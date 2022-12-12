# CMake in Boost

This document is meant to provide useful hints for Boost library maintainers to integrate CMake into their library.

## Quickstart
### Build
As the minimum you need a `CMakeLists.txt` file (or "CML") for short) in the root directory of the library.
The [CMakeLists from Boost.CI](CMakeLists.txt) can be used as a starting point with only small modifications required.

### Tests
You may also want a CML in the "test" folder for your tests.
To avoid duplicating tests in B2 and CMake you can use `include(BoostTestJamfile)` to get access to `boost_test_jamfile(FILE Jamfile.v2)` which will "translate" (only) `run <name>.cpp ;` into CMake tests.
You can also use `boost_test(NAME <name> SOURCES <name>.cpp)` to add tests semi-automated.  
Both read a CMake variable which you can set with `set(BOOST_TEST_LINK_LIBRARIES <Boost::lib-name>)` to have your Boost library linked to each test after adding it (see [below](#cmake-primer)).

See [BoostTest.cmake](https://github.com/boostorg/cmake/blob/develop/include/BoostTest.cmake)
(included by [BoostTestJamfile.cmake](https://github.com/boostorg/cmake/blob/develop/include/BoostTestJamfile.cmake))
for full details of the helper macros.

Of course you can use [`add_executable`](https://cmake.org/cmake/help/latest/command/add_executable.html) and [`add_test`](https://cmake.org/cmake/help/latest/command/add_test.html) to create your tests manually.   
You should then use a unique name for the created binaries.
The ones created by the `boost_test` macro use `${PROJECT_NAME}-` as the prefix for each test.

### CI Tests
Additionally the Boost.CI CI scripts reference subfolders of the `test` folder to test 2 common cases:
1. Searching for the installed library and using it.
1. Including the library to be built alongside the library/application that uses it.

For this the folders `cmake_install_test` and `cmake_subdir_test` are used for each case respectively.
They should contain a simple CML and a minimal program to check that the library can be linked to, its headers are found and the program runs.
There is no need for more than a very small "Hello World"-example here as the real tests should be in the (parent) "test" folder.

As there is practically no difference (or: "should be") between both use cases both can instead be combined into a single `cmake_test` folder with a single CML and CPP-file.
The CI config detects the presence of a `cmake_test` folder and configures each case with `BOOST_CI_INSTALL_TEST` set to either `ON` or `OFF`.
See the [Boost.CI cmake_test CML](test/cmake_test/CMakeLists.txt) for an example.

## CMake primer

Key elements usually required by Boost libraries are (in order of use, with `<name>` as placeholders):

- [`cmake_minimum_required`](https://cmake.org/cmake/help/latest/command/cmake_minimum_required.html)`(VERSION <version>)`:  
    Will error if the used CMake is older than specified.
    Possibly changes behavior according to [CMake policies](https://cmake.org/cmake/help/latest/command/cmake_policy.html), i.e. potentially incompatible changes introduced in some CMake version.
    The `<version>` can be `<min>...<max>` which basically means: Require at least CMake `<min>` and enable all policies up to the current CMake version or `<max>`.
- [`project`](https://cmake.org/cmake/help/latest/command/project.html)`(<boost-name> VERSION "${BOOST_SUPERPROJECT_VERSION}" LANGUAGES CXX)`:  
    **Must** come first (after `cmake_minimum_required`), the name should be specific & unique enough (e.g. `boost_locale`) but doesn't matter much.
    The version uses `BOOST_SUPERPROJECT_VERSION` set by the top-level [Boost CML](https://github.com/boostorg/boost/blob/da041154c6bac1a4aa98254a7d6819059e8ac0b0/CMakeLists.txt#L15)
    **if** that is used, i.e. not when the library is built on its own or as part of another project via [`add_subdirectory`](https://cmake.org/cmake/help/latest/command/add_subdirectory.html).
    Finally `LANGUAGES` overrides the default and avoids needlessly initializing the C compiler.
- [`add_library`](https://cmake.org/cmake/help/latest/command/add_library.html)`(boost_<name> <sources>)`:  
    Register the library and its source files as a target.
    `<sources>` is a list of relative paths (space separated so double-quote if the path contains spaces) and can (and should) contain headers too, so they show up in IDEs.
    For getting all headers without explicitely listing them use `file(GLOB_RECURSE headers include/*.hpp)` prior to this command and pass `${headers}` to this command.
    This is not recommended for source files because sources should be explicitely listed in order to regenerate the build system when the list of sources changes.  
    **Special case:** For [header-only libraries](#header-only-libraries) use `INTERFACE` instead of `<sources>`.
- [`add_library`](https://cmake.org/cmake/help/latest/command/add_library.html#alias-libraries)`(Boost::<name> ALIAS boost_<name>)`:  
    Register the ("Boost")-namespaced target which users will use instead of the `boost_<name>` target.
    This makes usage more conventional and allows to detect missing libraries earlier but the "real" target (the one with the sources) cannot have special characters in its name.
    Hence the need to have an actual library namespaced/prefixed with `"boost_"` and an alias prefixed with `"Boost::"`.  
    **IMPORTANT:** The `<name>` here and above **must** be the library/repository name with non-alphanumeric characters replaced by underscores in order to be compatible with expectations by the Boost super-project.
    Examples: `add_library(Boost::locale ALIAS boost_locale)`, `add_library(Boost::type_traits ALIAS boost_type_traits)`.  
    It makes sense to use the name of the real target (e.g. `boost_locale`) as the project name.
- [`target_include_directories`](https://cmake.org/cmake/help/latest/command/target_include_directories.html)`(boost_<name> PUBLIC include)`:  
    Add the `"include"` folder (i.e. a relative path) to the list of header search directories for this target/library and those using it (hence the `"PUBLIC"`).
    You can add more paths (space separated) and/or restrict the "scope" of those paths.
    To e.g. additionally add the "`src/helpers`" directory only when compiling this library use `target_include_directories(boost_<name> PUBLIC include PRIVATE src/helpers)` instead
    or `target_include_directories(boost_<name> PRIVATE src/helpers)` in addition to the above.
- [`target_link_libraries`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html)`(boost_<name> PUBLIC <list of libs> PRIVATE <list of libs>)`:  
    Add the libraries as dependencies.
    This means their `PUBLIC` includes are visibile when compiling `boost_<name>` and if the dependency is not header-only that library is linked to this library.
    If your "`PUBLIC`" headers include headers of a dependency then it needs to be here as `PUBLIC`.
    If you only include those headers in your compiled sources then the dependency can be `PRIVATE`.  
    Boost dependencies should be their namespaced name, e.g. `Boost::type_traits` or `Boost::core`.   
    **IMPORTANT:** Each Boost dependency must be listed on its own line because the Boost super-project uses a very simple dependency scanner.

Optionally you may want to use:

- [`target_sources`](https://cmake.org/cmake/help/latest/command/target_sources.html)`(boost_<name> PRIVATE <sources>)`:  
    If you don't want to or cannot pass (all) sources (and/or headers) to the `add_library` command you can add them with this command.
- [`target_compile_definitions`](https://cmake.org/cmake/help/latest/command/target_compile_definitions.html)`(boost_<name> PRIVATE <name>=<value>)`:  
    Add definitions to be used when compiling the library, i.e. `-D<name>=value`.
    The `=<value>` part is optional to define a valueless preprocessor symbol.
- [`target_compile_features`](https://cmake.org/cmake/help/latest/command/target_compile_features.html)`(boost_locale PUBLIC cxx_std_11)`:  
    Require (at least) C++11.
    Can also be used for any other (supported) [compiler feature](https://cmake.org/cmake/help/latest/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html).
- [`if`](https://cmake.org/cmake/help/latest/command/if.html)`(<condition>)\n<commands>\nendif()`:  
    CMake supports also conditionals.
    Often you want `if(<variable>)` (check if variable is not "false", i.e. unset, empty, `"OFF"`, `"FALSE"` etc.) or `if(<variable> STREQUAL "<string>")` or `if(NOT <variable> STREQUAL <other_variable>)`.  
    Examples:
    - `if(BOOST_SUPERPROJECT_SOURCE_DIR)`  
        If the super-project is being built
    - `if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)`  
        If CMake was invoked on the library folder, i.e. not the root Boost folder, using predefined variables.
    - `if(MSVC)`
        If the Visual Studio compiler is used.
    - `if(MSVC)`
        If the Visual Studio compiler is used.
    - `if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")  
        If either GCC or Clang (or "AppleClang") is used.

## Header-only libraries

All of the above applies (almost) unchanged to header-only libraries:  
They are added as (2) targets and with their dependencies just as compiled libraries but with `add_library(boost_<name> INTERFACE)`, i.e. no sources and use of `INTERFACE`.
The "sources" (i.e. headers) *can* then be added via [`target_sources`](https://cmake.org/cmake/help/latest/command/target_sources.html)`.

The only other difference is the use of `INTERFACE` instead of `PUBLIC`/`PRIVATE` in the `target_*` commands.

**Info:** `PUBLIC`, `PRIVATE` & `INTERFACE` are "scopes" in CMake. 
  - `PRIVATE`: Compile requirements, i.e. what is required for building the library.
  - `INTERFACE`: Usage requirements, i.e. what is required for using/linking to the library.
  - `PUBLIC`: Combines `PRIVATE` and `INTERFACE`, i.e. what is required for building **and** using the library.

To decide between `PUBLIC` and `PRIVATE` check what is visible in headers included by users, including transitive includes (e.g. `detail/*.hpp`).
For example:   
You most likely have a `<lib>/config.hpp` which is included by every header a user might include and that `config.hpp` includes `<boost/config.hpp>`.
Hence even though a user never includes your config header directly it will transitively be included and hence also `<boost/config.hpp>` from Boost.Config.
Therefore `Boost::config` is a `PUBLIC` dependency.

For header-only libraries **everything** is "user-visible" so `PUBLIC` but there is no compiled part so `INTERFACE` is enough (and `PUBLIC` would actually be an error reported by CMake).

## Boost super-project / Boost.CMake

CMake can be invoked on the Boost root folder due to its [CML](https://github.com/boostorg/boost/blob/master/CMakeLists.txt) which is its own project including each library as subprojects.  
Hence the top-level Boost project is called the "super-project".  
This is achieved with the [Boost.CMake](https://github.com/boostorg/cmake) submodule.
The most important CMake variables (passed on the command line as `cmake -D<name>=<value> <...>`) are:

- `BOOST_INCLUDE_LIBRARIES`: 
    Similar to the `--with<library>` B2 option
- `BOOST_EXCLUDE_LIBRARIES`: 
    Similar to the `--without-<library>` B2 option
- `CMAKE_BUILD_TYPE`:
    Can be e.g. `Debug` or `Release`
- `BUILD_SHARED_LIBS`:
    Set to `ON` for shared or `OFF` for static libraries.
- `BUILD_TESTING`:
    Set to `ON` or `OFF` (default) to build tests. This needs to be checked by [each libraries CML](https://github.com/boostorg/boost-ci/blob/dd0e6f1a934baa4ec8a588f36ef80fba9929fac2/CMakeLists.txt#L20-L22).

In short what the super-project does is check each library folder for a `CMakeLists.txt` and include that if found.
It will then search for the `Boost::<name>` and `boost_<name>` targets with `<name>` derived from the repository/folder name of the library.
Those targets will be added to-be-installed and the name and location of the library file are changed to match that of the B2 build.
The super-project build will also try to automatically find and include dependencies of the library by checking for lines containing **only** `Boost::<library>`.

**Note:** Building Boost via CMake is experimental!


