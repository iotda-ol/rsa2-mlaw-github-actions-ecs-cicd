#!/usr/bin/env python3
"""
Terraform validation and management utility script.

This script provides utilities to:
- Validate Terraform configurations
- Format Terraform files
- Check for common issues
- Generate reports
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Any


class TerraformValidator:
    """Validates and manages Terraform configurations."""

    def __init__(self, terraform_dir: str):
        """
        Initialize the validator.
        
        Args:
            terraform_dir: Path to the Terraform directory
        """
        self.terraform_dir = Path(terraform_dir)
        if not self.terraform_dir.exists():
            raise ValueError(f"Terraform directory not found: {terraform_dir}")

    def find_terraform_dirs(self) -> List[Path]:
        """Find all directories containing Terraform files."""
        tf_dirs = []
        for root, dirs, files in os.walk(self.terraform_dir):
            if any(f.endswith('.tf') for f in files):
                tf_dirs.append(Path(root))
        return tf_dirs

    def validate_syntax(self, directory: Path) -> bool:
        """
        Validate Terraform syntax in a directory.
        
        Args:
            directory: Directory to validate
            
        Returns:
            True if validation passes, False otherwise
        """
        print(f"Validating {directory}...")
        try:
            result = subprocess.run(
                ['terraform', 'fmt', '-check', '-recursive'],
                cwd=directory,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print(f"✓ {directory} is properly formatted")
                return True
            else:
                print(f"✗ {directory} has formatting issues:")
                print(result.stdout)
                return False
        except FileNotFoundError:
            print("Error: terraform command not found. Please install Terraform.")
            return False
        except Exception as e:
            print(f"Error validating {directory}: {e}")
            return False

    def format_files(self, directory: Path) -> bool:
        """
        Format Terraform files in a directory.
        
        Args:
            directory: Directory to format
            
        Returns:
            True if formatting succeeds, False otherwise
        """
        print(f"Formatting {directory}...")
        try:
            result = subprocess.run(
                ['terraform', 'fmt', '-recursive'],
                cwd=directory,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                if result.stdout:
                    print(f"Formatted files:\n{result.stdout}")
                else:
                    print(f"✓ All files already formatted")
                return True
            else:
                print(f"✗ Error formatting {directory}:")
                print(result.stderr)
                return False
        except FileNotFoundError:
            print("Error: terraform command not found. Please install Terraform.")
            return False
        except Exception as e:
            print(f"Error formatting {directory}: {e}")
            return False

    def check_variables(self, directory: Path) -> Dict[str, Any]:
        """
        Check for variables without defaults and missing descriptions.
        
        Args:
            directory: Directory to check
            
        Returns:
            Dictionary with validation results
        """
        issues = {
            'missing_descriptions': [],
            'missing_defaults': []
        }
        
        variables_file = directory / 'variables.tf'
        if not variables_file.exists():
            return issues
            
        # Simple parsing - look for variable blocks
        with open(variables_file, 'r') as f:
            content = f.read()
            
        # This is a basic check - a proper parser would be better
        in_variable = False
        current_var = None
        has_description = False
        has_default = False
        
        for line in content.split('\n'):
            line = line.strip()
            
            if line.startswith('variable'):
                if current_var and in_variable:
                    # Check previous variable
                    if not has_description:
                        issues['missing_descriptions'].append(current_var)
                    # Only required variables need defaults
                    
                # Start new variable
                current_var = line.split('"')[1] if '"' in line else None
                in_variable = True
                has_description = False
                has_default = False
                
            elif in_variable:
                if 'description' in line:
                    has_description = True
                if 'default' in line:
                    has_default = True
                if line == '}' and current_var:
                    # End of variable block
                    if not has_description:
                        issues['missing_descriptions'].append(current_var)
                    in_variable = False
                    
        return issues

    def generate_report(self) -> Dict[str, Any]:
        """
        Generate a comprehensive validation report.
        
        Returns:
            Dictionary with validation results
        """
        report = {
            'terraform_dirs': [],
            'validation_passed': True,
            'issues': []
        }
        
        tf_dirs = self.find_terraform_dirs()
        report['terraform_dirs'] = [str(d) for d in tf_dirs]
        
        for directory in tf_dirs:
            dir_report = {
                'directory': str(directory),
                'formatted': self.validate_syntax(directory),
                'variable_issues': self.check_variables(directory)
            }
            
            if not dir_report['formatted']:
                report['validation_passed'] = False
                
            if dir_report['variable_issues']['missing_descriptions']:
                report['issues'].append({
                    'directory': str(directory),
                    'type': 'missing_descriptions',
                    'variables': dir_report['variable_issues']['missing_descriptions']
                })
                
        return report


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Terraform validation and management utility'
    )
    parser.add_argument(
        'command',
        choices=['validate', 'format', 'report'],
        help='Command to execute'
    )
    parser.add_argument(
        '--terraform-dir',
        default='terraform',
        help='Path to Terraform directory (default: terraform)'
    )
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output results in JSON format'
    )
    
    args = parser.parse_args()
    
    try:
        validator = TerraformValidator(args.terraform_dir)
        
        if args.command == 'validate':
            tf_dirs = validator.find_terraform_dirs()
            all_valid = True
            for directory in tf_dirs:
                if not validator.validate_syntax(directory):
                    all_valid = False
            sys.exit(0 if all_valid else 1)
            
        elif args.command == 'format':
            tf_dirs = validator.find_terraform_dirs()
            all_formatted = True
            for directory in tf_dirs:
                if not validator.format_files(directory):
                    all_formatted = False
            sys.exit(0 if all_formatted else 1)
            
        elif args.command == 'report':
            report = validator.generate_report()
            if args.json:
                print(json.dumps(report, indent=2))
            else:
                print("\n=== Terraform Validation Report ===\n")
                print(f"Directories checked: {len(report['terraform_dirs'])}")
                print(f"Overall status: {'PASS' if report['validation_passed'] else 'FAIL'}\n")
                
                if report['issues']:
                    print("Issues found:")
                    for issue in report['issues']:
                        print(f"  - {issue['directory']}: {issue['type']}")
                        for var in issue['variables']:
                            print(f"    • {var}")
                else:
                    print("No issues found!")
                    
            sys.exit(0 if report['validation_passed'] else 1)
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
