---
title: Documentation Site
layout: /src/layouts/autonum.astro
sidebar:
  label: Doc Site
  order: 60
  badge:
    text: Dev
---

This page "documents" this "document site" itself.

The repo of this doc site is [here](https://github.com/end-4/dots-hyprland-wiki) and it's open to contribution.

# Contribute to dots-hyprland-wiki
We sincerely thanks for all contributors.

You're welcomed to submit any kind of beneficial Pull Request, though it's our final decision to merge it or not.

If you're unsure about a possible PR, you may create a Discussion before you work on it.

:::caution
Always prioritize updating the English documents,
so that other languages can be uniformly updated through English translation.
:::

## Content
Typically, if you have successfully contributed a new function/workflow/... to [dots-hyprland](https://github.com/end-4/dots-hyprland),
and if it needs documentation, then you're very welcomed to submit a PR here to document it.

Troubleshooting related contents are also welcomed.

## Translation

This site has i18n support, and it's our thing to do rest of work, i.e. l10n.

:::note
Please don't waste your time on translating Dev Notes. See [#1](https://github.com/end-4/dots-hyprland-wiki/issues/1#issuecomment-1938696111) for reason.
:::

**See more under the section [How to - l10n](#l10n) below.**

# Development

Currently, this project is based on Starlight, which is based on Astro.

The website is hosted on GitHub Pages.

## Run Locally

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm install`             | Installs dependencies                            |
| `npm run dev`             | Starts local dev server at `localhost:4321`      |
| `npm run build`           | Build your production site to `./dist/`          |
| `npm run preview`         | Preview your build locally, before deploying     |
| `npm run astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `npm run astro -- --help` | Get help using the Astro CLI                     |

:::tip
If this error occured: `vips/vips8: no such file or directory`, you may install `libvips` manually, e.g. on Arch Linux: `sudo pacman -S libvips`
:::

:::caution
When running locally, there seems to be a bug that it does NOT apply a proper base url. But it seems okay on GitHub Pages.
Therefore, do NOT easily "fix" a relative link just because a `404` happened locally. Otherwise, while the link for locally hosted site is "fixed", the site on GitHub Pages will be broken.
Similarly, open <http://localhost:4321/dots-hyprland-wiki/en>, NOT <http://localhost:4321/dots-hyprland-wiki> when running locally.
:::

## How to

- Edit/add pages: Edit markdown files under `src/content/docs/en/` (Somehow different to the markdown on GitHub. [Reference](https://starlight.astro.build/guides/authoring-content)).

:::note
There some numbers before the markdown files, but normally they do not have any meanings, just for auto arranging on sidebar.
:::

> To publish HTML files, put it under `src/pages`.

- Edit sidebar: Edit `astro.config.mjs`.

- Edit theme: Edit `src/styles/custom.css` ([Reference](https://starlight.astro.build/guides/css-and-tailwind/)).

- Edit homepage: Edit `src/content/docs/en/index.mdx`

:::caution
> When generating link paths, the uppercase characters inside original markdown filename will be converted to lowercase, and the `.` will be removed. If you still use the original filename as link path, it may result in a `404`.
:::

### l10n

- Manage languages: Edit `astro.config.mjs`.
- Translate group labels on sidebar: Edit `astro.config.mjs`.
- Translate pages: Under `src/content/docs/<lang>/`. Filenames and folder structure are exact the same as which under `src/content/docs/en/`.

:::caution
Use **lowercase** for language labels, except for the `lang:` and group-label on sidebar in `astro.config.mjs`.
Example: in astro.config.mjs:
```mjs
        'zh-cn': {
          label: '简体中文', //Simplified Chinese
          lang: 'zh-CN',
        },
...
        label: 'General',
        translations: {
          'zh-CN': '通用',
        },
```
As well for the directory name, e.g. `src/content/docs/zh-cn`
:::

## References

- [Astro documentation](https://docs.astro.build)
- [Starlight’s docs](https://starlight.astro.build/)
- [Expressive-code](https://expressive-code.com/)

# History
This doc site started from [dots-hyprland#246](https://github.com/end-4/dots-hyprland/issues/246) and was then initialized mainly by [@clsty](https://github.com/clsty) with contents from the README and built-in wiki of [dots-hyprland](https://github.com/end-4/dots-hyprland) and the README of [dots-hyprarch](https://github.com/clsty/dots-hyprarch).