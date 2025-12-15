Plan: Git + GitHub Pages for Worlds
===================================

Context
- Delphi project in this folder; /blog exists and is currently empty.
- Goals: 1) put project under Git with a sensible history, 2) host a development blog via GitHub Pages.
- Assumptions: Windows, Git installed, GitHub account available.
- Decisions: Blog uses Jekyll; repo will be public; include a README; use the least restrictive license (suggest MIT unless you prefer Unlicense).

Step-by-step plan (who does what)
1) Preflight (You)
- Verify Git identity: git config --global --get user.name and git config --global --get user.email. Set if missing/incorrect via git config --global user.name "Your Name" and git config --global user.email "you@example.com". Confirm git --version works.
- Visibility: public (chosen).
- License: least restrictive; default to MIT unless you explicitly want Unlicense.

2) Repo scaffolding (Copilot can do)
- Add a Delphi-aware .gitignore covering IDE/build outputs plus Jekyll artifacts (_site, .jekyll-cache, .sass-cache, vendor/cache, node_modules if present).
- Add README.md summarizing the app and pointing to the blog.
- Add LICENSE (MIT by default unless you confirm Unlicense).

3) Initialize Git locally (You, or Copilot on request)
- In the project root: git init, then git status to confirm the working tree.

4) Stage and commit baseline (You)
- Review the generated .gitignore; run git add . and git commit -m "Initialize Worlds project".

5) Create GitHub repository (You)
- On github.com, create repo "Worlds" (no auto README/gitignore). Copy the remote URL (HTTPS or SSH).

6) Connect and push (You)
- git branch -M main
- git remote add origin <repo-url>
- git push -u origin main

7) Blog scaffolding (Copilot can do)
- Set up Jekyll in /blog with minimal _config.yml, index.md, and standard _posts structure so GitHub Pages can build it.

8) Pages workflow (Copilot drafts; You review/enable)
- Add .github/workflows/pages.yml using official GitHub Pages actions, setting working-directory: blog and output to the gh-pages branch.
- In GitHub Settings → Pages, set Source to GitHub Actions. First push of the workflow will publish.

9) Verify deployment (You)
- After the workflow runs, check the Pages URL (https://<user>.github.io/Worlds or custom domain). Inspect the build log if it fails.

10) Ongoing hygiene (Shared)
- Use feature branches for changes, keep build outputs out of Git, and add blog posts by committing new Markdown files under /blog (_posts if Jekyll).
