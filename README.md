# Crystal Realtime Service

A simple websocket service to broadcast realtime events powered by JWTs

## Quickstart

You can deploy this service straight to heroku and skip most of the setup.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

You need to have [crystal lang](https://crystal-lang.org/) installed

```
brew install crystal-lang
```

### Setup

Create a `.env` file in the root of this repository with the following environment variables, or set the variables if deploying to heroku.

```
JWT_SECRET=[64 chars]
crystal b
```

### Running the app

[Sentry](https://github.com/samueleaton/sentry) is used to run the app and recompile when files change

```
./sentry
```

## Running the tests

```
crystal spec
```

## Built With

* [Crystal lang](https://crystal-lang.org/)
* [Kemal](https://github.com/kemalcr/kemal) - Web microframework for crystal

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Pete Hawkins** - [phawk](https://github.com/phawk)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
