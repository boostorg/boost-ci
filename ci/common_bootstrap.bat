REM Generic bootstrap script for Windows, creates B2 and the headers
REM It needs to be executed from within BOOST_ROOT

REM Bootstrap is not expecting B2_CXXFLAGS content so we zero it out for the bootstrap only
SET B2_CXXFLAGS=
cmd /c bootstrap
IF NOT %ERRORLEVEL% == 0 (
    type bootstrap.log
    EXIT /B 1
)

b2 headers
