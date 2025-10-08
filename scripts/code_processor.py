#!/usr/bin/env python3
import sys
import os
import subprocess
from pygments import highlight
from pygments.lexers import get_lexer_by_name, guess_lexer
from pygments.formatters import Terminal256Formatter

def run_formatter(tool, code):
    """Runs an external formatting tool on the code."""
    try:
        if tool == 'black':
            # Black is for Python
            process = subprocess.run(['black', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        elif tool == 'autopep8':
            # autopep8 is for Python
            process = subprocess.run(['autopep8', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        elif tool == 'shfmt':
            # shfmt is for shell scripts
            process = subprocess.run(['shfmt', '-i', '4', '-ci', '-'], input=code.encode('utf-8'), capture_output=True, check=True)
            return process.stdout.decode('utf-8'), None
        # Add other formatters here (e.g., prettier for JS/TS/CSS)
        return code, None
    except subprocess.CalledProcessError as e:
        return code, f"Formatter {tool} failed: {e.stderr.decode('utf-8').strip()}"
    except FileNotFoundError:
        return code, f"Formatter {tool} not found. Skipping."
    except Exception as e:
        return code, f"Formatter {tool} error: {str(e)}"

def run_analysis(tool, file_path):
    """Runs a static analysis tool (like pylint) on the file."""
    try:
        if tool == 'pylint':
            # Pylint is for Python
            process = subprocess.run(['pylint', file_path], capture_output=True, check=False)
            # Filter out the summary and keep only the errors/warnings
            output = process.stdout.decode('utf-8')
            analysis_output = "\n".join([line for line in output.splitlines() if not line.startswith('---') and not line.startswith('Your code has been rated')])
            return analysis_output
        # Add other analyzers here (e.g., eslint)
        return ""
    except FileNotFoundError:
        return f"Analyzer {tool} not found. Skipping."
    except Exception as e:
        return f"Analyzer {tool} error: {str(e)}"

def process_code_file(file_path, file_extension):
    """Reads, formats, analyzes, and highlights a code file."""
    try:
        with open(file_path, 'r') as f:
            code = f.read()
    except Exception as e:
        print(f"\x1b[31m[ERROR] Could not read file: {file_path}. {str(e)}\x1b[0m", file=sys.stderr)
        return

    # 1. Determine Language and Lexer
    if file_extension == 'py':
        lang = 'python'
        formatter_tools = ['black', 'autopep8']
        analyzer_tools = ['pylint']
    elif file_extension == 'sh':
        lang = 'bash'
        formatter_tools = ['shfmt']
        analyzer_tools = []
    elif file_extension in ['js', 'ts', 'jsx', 'tsx', 'css', 'html']:
        lang = file_extension
        formatter_tools = [] # Prettier/ESLint would go here
        analyzer_tools = []
    else:
        lang = 'text'
        formatter_tools = []
        analyzer_tools = []

    # 2. Formatting
    formatted_code = code
    format_log = []
    for tool in formatter_tools:
        formatted_code, error = run_formatter(tool, formatted_code)
        if error:
            format_log.append(error)
        else:
            format_log.append(f"Formatter {tool} applied successfully.")

    # 3. Analysis
    analysis_log = []
    for tool in analyzer_tools:
        analysis_output = run_analysis(tool, file_path)
        if analysis_output:
            analysis_log.append(f"\x1b[1;33m--- {tool.upper()} ANALYSIS ---\x1b[0m\n{analysis_output}")

    # 4. Syntax Highlighting
    try:
        lexer = get_lexer_by_name(lang, stripall=True)
    except:
        lexer = guess_lexer(formatted_code)
        
    formatter = Terminal256Formatter(style='monokai')
    highlighted_code = highlight(formatted_code, lexer, formatter)

    # 5. Output Results
    print(f"\n\x1b[1;36m--- CODE ANALYSIS & FORMATTING REPORT ---\x1b[0m")
    print(f"\x1b[34mFile:\x1b[0m {file_path}")
    print(f"\x1b[34mLanguage:\x1b[0m {lang}")
    print(f"\x1b[34mFormatting Log:\x1b[0m {'; '.join(format_log)}")
    
    if analysis_log:
        print(f"\n\x1b[1;31m--- STATIC ANALYSIS FINDINGS ---\x1b[0m")
        print('\n'.join(analysis_log))
    
    print(f"\n\x1b[1;32m--- SYNTAX HIGHLIGHTED CODE ---\x1b[0m")
    print(highlighted_code)
    print(f"\x1b[1;36m-------------------------------------------\x1b[0m")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: code_processor.py <file_path> <file_extension>", file=sys.stderr)
        sys.exit(1)
    
    file_path = sys.argv # FIX: Get the first argument
    file_extension = sys.argv # FIX: Get the second argument
    
    process_code_file(file_path, file_extension)
