# Covenience script for setting up wildcard DNS resolver in localhost on OSX

## This script:

```
- If not present - installs homebrew package manager
- Installs `dnsmasq` service (if not present)
- Configures `dnsmasq` with domain provided and loads it
```

## Tested OSX Versions

```
- 12.4 (Monterey)
```

## Setup

```sh
# To setup dns resolving for '*.docker' addresses, run:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/beslovas/dnsmasq4dev/master/setup.sh)" -- -d docker
```

## --help

```sh

    dnsmasq4dev.sh --domain <domain>

    --domain -d <domain>    Domain to setup wildcard support
    -h --help               Show this help dialog

```

