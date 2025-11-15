# Testing the Dotfiles Setup with Podman

This directory contains test scripts for validating the setup automation in containerized environments using Podman.

## Prerequisites

### Install Podman

**Fedora:**
```bash
sudo dnf install -y podman podman-compose
```

**Ubuntu/Debian:**
```bash
sudo apt install -y podman podman-compose
```

### Enable Rootless Podman (Recommended)

```bash
# Start the rootless socket
systemctl --user start podman.socket
systemctl --user enable podman.socket

# Verify it's running
systemctl --user status podman.socket
```

## Quick Start

### Run All Tests

```bash
cd tests
bash run-tests.sh all
```

### Test Specific Distribution

```bash
# Test Fedora
bash run-tests.sh fedora

# Test Ubuntu
bash run-tests.sh ubuntu

# Test Debian
bash run-tests.sh debian
```

### Keep Container for Inspection

```bash
bash test-setup.sh fedora --keep-container

# Later, inspect the container
podman exec -it dotfiles-test-fedora-<timestamp> bash

# Clean up when done
podman rm -f dotfiles-test-fedora-<timestamp>
```

## Test Coverage

The test suite validates:

✓ **File Structure**
- All required scripts present
- Configuration files valid
- Helper functions loadable

✓ **Script Syntax**
- Bash syntax validation
- No syntax errors in scripts

✓ **Distribution Support**
- Fedora (dnf package manager)
- Ubuntu (apt package manager)
- Debian (apt package manager)

✓ **Dry-Run Mode**
- Scripts execute without errors
- No actual installations performed
- Safe preview of changes

✓ **Configuration**
- setup.conf loads correctly
- All variables are defined
- No missing dependencies

## Test Output

Each test generates:
- **Test log:** `test-results-{distro}-{timestamp}.log`
- **Detailed output:** Shows which checks passed/failed
- **Summary report:** Quick overview of results

## Example Test Run

```bash
$ bash run-tests.sh fedora

[✓] Podman is installed: podman version 5.0.0
[✓] Podman is accessible
[→] Testing Fedora setup...
[→] Testing dotfiles setup with fedora
[→] Container: dotfiles-test-fedora-1731600123
[→] Log file: test-results-fedora-20231115_143512.log
[✓] Podman is available: podman version 5.0.0
[→] Pulling image: fedora:latest
[✓] Image pulled successfully
[→] Creating test container...
[✓] Container created: dotfiles-test-fedora-1731600123
[→] Installing base dependencies...
[✓] Base dependencies installed
[→] Running preflight checks...
[✓] Preflight checks passed
...
[✓] Test completed successfully!
[→] Full test log: test-results-fedora-20231115_143512.log
```

## Common Issues

### "Podman permission denied"

Run as user with sudo or enable rootless Podman:
```bash
systemctl --user start podman.socket
```

### "Image pull failed"

Check internet connectivity:
```bash
podman pull alpine  # Simple test
```

### Container inspection

Keep the container for debugging:
```bash
bash test-setup.sh fedora --keep-container
podman exec -it <container-name> bash
```

### View test logs

```bash
# Latest fedora test
cat test-results-fedora-*.log | tail -100

# Grep for errors
grep -i error test-results-*.log
```

## CI/CD Integration

Run tests in GitHub Actions or similar:

```yaml
- name: Test with Podman
  run: |
    cd tests
    bash run-tests.sh all
```

## Manual Testing

For interactive testing inside container:

```bash
# Create and enter container
podman run -it --name test-fedora \
  -v $(pwd):/dotfiles:z \
  fedora:latest bash

# Inside container
cd /dotfiles

# Preview changes
./main-setup.sh --dry-run -vv

# Exit
exit

# Clean up
podman rm test-fedora
```

## Notes

- Tests use rootless Podman for security
- No actual packages are installed during testing
- Containers are automatically cleaned up after tests
- All test logs are preserved for review
- Use `--keep-container` to inspect containers

---

**Happy testing!**