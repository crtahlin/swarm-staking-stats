# Description

An app using the [Shiny](https://www.shinyapps.io/) platform on top of [R](https://cran.r-project.org/), reading data from [swarmscan.io](https://swarmscan.io/) and rendering various statistics on screen.

# Disclaimer

The app is meant to be informative in nature, no guarantees are made about correctness of displayed statistics.

# Instructions

## Building docker image localy
```
git clone https://github.com/crtahlin/swarm-staking-stats.git
cd swarm-network-stats
docker build -t swarm-staking-public .
docker run --rm -p 3838:3838 swarm-staking-public:latest
```

Open in browser: `localhost:3838/`

