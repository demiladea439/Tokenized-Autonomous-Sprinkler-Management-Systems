# Tokenized Autonomous Sprinkler Management System

A decentralized autonomous sprinkler management system built on the Stacks blockchain using Clarity smart contracts. This system provides intelligent irrigation management through tokenized governance and real-time monitoring.

## System Overview

The system consists of five independent smart contracts that work together to provide comprehensive sprinkler management:

### Core Contracts

1. **Soil Moisture Contract** (`soil-moisture.clar`)
    - Monitors ground hydration levels in real-time
    - Tracks moisture readings across different zones
    - Provides threshold-based alerts

2. **Weather Integration Contract** (`weather-integration.clar`)
    - Integrates weather data and rainfall predictions
    - Adjusts watering schedules based on forecasts
    - Manages weather-based irrigation decisions

3. **Plant Requirement Contract** (`plant-requirements.clar`)
    - Customizes irrigation for different vegetation types
    - Manages plant profiles and water requirements
    - Optimizes watering schedules per plant type

4. **Water Conservation Contract** (`water-conservation.clar`)
    - Minimizes water usage while maintaining lawn health
    - Tracks water consumption and efficiency metrics
    - Implements conservation strategies

5. **System Maintenance Contract** (`system-maintenance.clar`)
    - Tracks sprinkler head performance and repairs
    - Manages maintenance schedules and alerts
    - Monitors system health and diagnostics

## Features

- **Decentralized Governance**: Token-based voting for system parameters
- **Real-time Monitoring**: Continuous soil moisture and weather tracking
- **Intelligent Automation**: AI-driven irrigation decisions
- **Water Conservation**: Optimized usage patterns
- **Maintenance Tracking**: Proactive system health monitoring
- **Multi-zone Support**: Independent management of different areas
- **Plant-specific Care**: Customized irrigation per vegetation type

## Token Economics

- **Governance Tokens**: Vote on system parameters and upgrades
- **Utility Tokens**: Pay for water usage and system services
- **Reward Tokens**: Incentivize conservation and maintenance

## Installation

1. Clone the repository
2. Install Clarinet CLI
3. Run tests: \`clarinet test\`
4. Deploy contracts: \`clarinet deploy\`

## Usage

### Setting Up Zones

\`\`\`clarity
;; Register a new irrigation zone
(contract-call? .soil-moisture register-zone u1 u30 u70)
\`\`\`

### Adding Plant Profiles

\`\`\`clarity
;; Add a plant type with water requirements
(contract-call? .plant-requirements add-plant-type "roses" u50 u80 u2)
\`\`\`

### Monitoring System

\`\`\`clarity
;; Check soil moisture levels
(contract-call? .soil-moisture get-moisture-level u1)
\`\`\`

## Testing

Run the test suite using Vitest:

\`\`\`bash
npm test
\`\`\`

## Architecture

The system follows a modular architecture where each contract operates independently without cross-contract calls. This ensures:

- **Reliability**: Failure in one contract doesn't affect others
- **Scalability**: Contracts can be upgraded independently
- **Security**: Reduced attack surface
- **Maintainability**: Clear separation of concerns

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support and questions, please open an issue in the GitHub repository.
