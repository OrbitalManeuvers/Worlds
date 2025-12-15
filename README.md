# Worlds

Delphi project for the Worlds application, with a GitHub Pages-backed development blog in the `/blog` directory.

## What this repo contains
- Delphi source: project files (`Worlds.dpr`, `.dproj`) and units under the root and `engine/`.
- Blog: Jekyll site in `/blog`, deployed via GitHub Pages Actions.

## Working with the repo
1. Clone and open in Delphi.
2. Build artifacts live outside source control (see `.gitignore`).
3. Blog: edit content under `/blog`; posts live in `/blog/_posts`.

### Run the blog locally (optional)
If you have Ruby/Jekyll locally:
1. `cd blog`
2. `bundle exec jekyll serve`
3. Browse http://localhost:4000/Worlds/

## Deployment
- GitHub Actions workflow in `.github/workflows/pages.yml` builds the Jekyll site from `/blog` and publishes to GitHub Pages (branch: `gh-pages`).
- GitHub Pages settings: Source = GitHub Actions.

## License
MIT License (see LICENSE).
