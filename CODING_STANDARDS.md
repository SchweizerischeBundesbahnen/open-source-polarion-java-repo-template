# Repository Coding Standards

The purpose of the Coding Standards is to create a baseline for collaboration and review within various aspects of our open source project and community, from core code to themes to plugins.

Coding standards help avoid common coding errors, improve the readability of code, and simplify modification. They ensure that files within the project appear as if they were created by a single common unit.

Following the standards means anyone will be able to understand a section of code and modify it, if needed, without regard to when it was written or by whom.

If you are planning to contribute, you need to familiarize yourself with these standards, as any code you submit will need to comply with them.

## Java Coding Standards and Best Practices

This document outlines the coding standards and best practices to be followed when writing Java code for this project. Consistency in coding style and adherence to best practices not only improve code readability but also facilitate collaboration and maintenance.

### Coding Standards Guidelines

Please refer to the following coding standards guidelines for detailed recommendations:

1. [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) - Google's Java style guide offers comprehensive guidelines on coding style, naming conventions, documentation, and more.

2. [Oracle's Java Code Conventions](https://www.oracle.com/java/technologies/javase/codeconventions-contents.html) - Oracle provides a set of conventions for writing Java code, covering formatting, naming conventions, and other aspects of coding style.

### Linters

We recommend using the following linters to enforce coding standards and best practices in your Java code:

1. [Checkstyle](https://checkstyle.org/) - Checkstyle is a static code analysis tool that checks Java code against a set of coding standards. It can detect violations of coding conventions, potential bugs, and other code quality issues.

2. [FindBugs](http://findbugs.sourceforge.net/) - FindBugs is a static analysis tool that detects potential bugs in Java code. It can identify common programming errors, performance issues, and security vulnerabilities.

3. [PMD](https://pmd.github.io/) - PMD is a source code analyzer that finds common programming flaws like unused variables, empty catch blocks, and unnecessary object creation. It provides actionable feedback to improve code quality.

4. [SpotBugs](https://spotbugs.github.io/) - SpotBugs is the successor of FindBugs, offering more features and improved bug detection capabilities. It performs static analysis to identify bugs and other issues in Java bytecode.

## Python Coding Standards and Best Practices

This document outlines the coding standards and best practices to be followed when writing Python code for this project. Consistency in coding style and adherence to best practices not only improve code readability but also facilitate collaboration and maintenance.

### Coding Standards Guidelines

Please refer to the following coding standards guidelines for detailed recommendations:

1. [PEP 8](https://pep8.org/) - Python Enhancement Proposal 8 provides the de facto style guide for Python code, covering formatting, naming conventions, and more.
   
2. [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html) - Google's Python style guide offers comprehensive guidelines on coding style, naming conventions, documentation, and more.

### Linters

We recommend using the following linters to enforce coding standards and best practices in your Python code:

1. [flake8](https://flake8.pycqa.org/en/latest/) - Flake8 combines multiple linters including pycodestyle, pyflakes, and McCabe complexity checker to analyze your code against the PEP 8 style guide and detect various errors and inconsistencies.

2. [pylint](https://pylint.pycqa.org/) - Pylint analyzes Python code for errors, potential bugs, and code smells, providing detailed reports with suggestions for improvement.

3. [black](https://black.readthedocs.io/en/stable/) - Black is an opinionated code formatter for Python that automatically reformats your code to ensure consistent style adherence.

4. [mypy](http://mypy-lang.org/) - Mypy is a static type checker for Python that helps detect and prevent type-related errors using optional static typing.

---

This setup provides both the high-level guidelines for coding standards and best practices, as well as practical tools (linters) that can be used to enforce these standards in your project.
