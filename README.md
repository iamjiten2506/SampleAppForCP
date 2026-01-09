# Simple CI/CD Application

A minimal Node.js application for demonstrating CI/CD with AWS CodePipeline, CodeBuild, and CodeDeploy.

## Application Structure

- `src/app.js` - Main Express application
- `src/package.json` - Node.js dependencies
- `buildspec.yml` - CodeBuild configuration
- `appspec.yml` - CodeDeploy configuration
- `scripts/` - Deployment lifecycle scripts

## Manual Setup Guide

Follow the step-by-step instructions in `SETUP_INSTRUCTIONS.md` to create the CI/CD pipeline using AWS Console and GitHub.

## Local Development

```bash
cd src
npm install
npm start
```

Visit `http://localhost:3000` to see the application running.