# Apocrypha Contracts

Minimal ERC721 implementation for academic articles. Distribution of access control tokens from licensed holders.

## Architecture


## Installation

### Foundry

First run the command below to get `foundryup`, the Foundry toolchain installer:

```sh
curl -L https://foundry.paradigm.xyz | bash
```

If you do not want to use the redirect, feel free to manually download the
foundryup installation script from
[here](https://raw.githubusercontent.com/gakonst/foundry/master/foundryup/install).

Then, in a new terminal session or after reloading your `PATH`, run it to get
the latest `forge` and `cast` binaries:

```sh
foundryup
```

Advanced ways to use `foundryup`, and other documentation, can be found in the
[foundryup package](./foundryup/README.md). Happy forging!

### Hardhat

`npm install` or `yarn`
```
### Tests

```
forge test -vv
```

## Directory Structure

```
integration
|- mover.test.ts - "Hardhat integration tests"
lib
|- forge-std - "Test dependency"
scripts
`- deploy.ts - "hardhat deploy script"
src
|- test
|  |- mocks
|  |  `- MockNFT.sol - "Mock NFT for testing"
|  `- Mover.t.sol - "Unit testi in solidity"
`- Mover.sol - "Solidity contract"
.env.example - "Expamle dot env"
.gitignore - "Ignore workfiles"
.gitmodules -  "Dependecy modules"
.solcover.js - "Configure coverage"
.solhint.json - "Configure solidity lint"
foundry.toml - "Configure foundry"
hardhat.config.ts - "Configure hardhat"
package.json - "Node dependencies"
README.md - "This file"
remappings.txt - "Forge dependcy mappings"
slither.config.json - "Configure slither"
```
