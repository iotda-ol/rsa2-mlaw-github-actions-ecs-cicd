# Scripts

This directory contains utility scripts for managing and validating the infrastructure.

## terraform_validator.py

A Python utility for validating and formatting Terraform configurations.

### Requirements

- Python 3.6+
- Terraform CLI

### Usage

**Validate Terraform formatting:**
```bash
python3 scripts/terraform_validator.py validate
```

**Format Terraform files:**
```bash
python3 scripts/terraform_validator.py format
```

**Generate validation report:**
```bash
python3 scripts/terraform_validator.py report
```

**Generate JSON report:**
```bash
python3 scripts/terraform_validator.py report --json
```

### Options

- `--terraform-dir`: Path to Terraform directory (default: `terraform`)
- `--json`: Output results in JSON format

### Examples

```bash
# Validate all Terraform files
./scripts/terraform_validator.py validate

# Format all Terraform files
./scripts/terraform_validator.py format

# Generate a detailed report
./scripts/terraform_validator.py report

# Generate JSON report for CI/CD integration
./scripts/terraform_validator.py report --json > validation-report.json
```
