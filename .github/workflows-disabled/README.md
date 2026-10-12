# Disabled workflows

These workflows come from upstream PdfCraft and call reusable workflows in
`storytold/craft-common-actions` and self-hosted runners (`macos-release`, Windows ARM64) that only
exist in the ArtCraft team's GitHub organisation, along with their code-signing secrets. They are kept
here for reference. To ship your own releases, copy the steps you need into a workflow in
`../workflows/` that runs on GitHub-hosted runners and uses your own signing certificates.
