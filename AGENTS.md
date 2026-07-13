## Bash Command Constraints
- NEVER use multi-line Bash commands, multi-line heredocs, loops, or conditionals in the terminal.
- NEVER chain multiple commands using `&&`, `||`, or `|`. 
- If a task requires multiple lines or complex logic, write the commands to a temporary shell script file using the file editing tools, then execute that script file in a single line.
- Always execute commands sequentially as single-line, atomic statements.
