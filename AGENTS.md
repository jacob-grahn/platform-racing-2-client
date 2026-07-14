## Bash Command Constraints
- NEVER use multi-line Bash commands, multi-line heredocs, loops, or conditionals in the terminal.
- NEVER chain multiple commands using `&&`, `||`, or `|`. 
- If a task requires multiple lines or complex logic, write the commands to a temporary shell script file using the file editing tools, then execute that script file in a single line.
- Always execute commands sequentially as single-line, atomic statements.

## Test Suite Constraints
- Use focused deterministic tests for the domain you are working on. Pass one or more domain flags to `./test.sh` (for example, `./test.sh --physics --blocks`, `./test.sh --level-rendering`, or `./test.sh --lobby --items`). Multiple flags run the union of those domains.
- For small generic changes that are not tied to a specific domain, run only the default smoke suite with `./test.sh`.
- Available domain flags are `--audio`, `--blocks`, `--character`, `--crypto`, `--data`, `--effects`, `--gameplay`, `--items`, `--level-editor`, `--level-rendering`, `--lobby`, `--network`, `--physics`, `--runtime`, and `--ui`. Run `./test.sh --help` to see the current list.
- NEVER run the full deterministic suite unless the user explicitly requests it. The full suite is invoked with `./test.sh --full`.
- Do not run `tools/test_all.sh` unless the user explicitly requests full local verification; it includes the full deterministic suite.
