"""Publish only a fully packaged successful build; never replace a published version."""
import json
import os
from pathlib import Path
import plistlib
import subprocess


def gh(*args, check=True):
    return subprocess.run(["gh", *args], text=True, capture_output=True, check=check)


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    sha = os.environ["GITHUB_SHA"]
    info = plistlib.loads(Path("Payload/TelShevaAzan.app/Info.plist").read_bytes())
    version = info["CFBundleShortVersionString"]
    build = info["CFBundleVersion"]
    tag = f"v{version}-b{build}"
    assets = ["TelShevaAzan-unsigned.ipa", "TelShevaAzan-unsigned.tipa", "build-diagnostics.txt"]
    for asset in assets:
        if not Path(asset).is_file() or Path(asset).stat().st_size == 0:
            raise RuntimeError(f"Missing release asset: {asset}")

    existing = gh("release", "view", tag, "--repo", repo, "--json", "targetCommitish,isDraft,assets", check=False)
    if existing.returncode == 0:
        release = json.loads(existing.stdout)
        if release["targetCommitish"] != sha:
            raise RuntimeError("This version already belongs to another commit. Increase the app version/build.")
        if not release["isDraft"]:
            uploaded = {a["name"]: a["size"] for a in release["assets"]}
            if not all(uploaded.get(a) == Path(a).stat().st_size for a in assets):
                raise RuntimeError("Published release assets do not match this build; use a new version.")
            print(f"Release already published: {tag}")
            return
        gh("release", "upload", tag, *assets, "--repo", repo, "--clobber")
        gh("release", "edit", tag, "--repo", repo, "--draft=false", "--latest")
    else:
        notes = Path(os.environ["RUNNER_TEMP"]) / "salati-release-notes.txt"
        notes.write_text(
            f"صلاتي {version} ({build})\n\n"
            "نزّل TelShevaAzan-unsigned.ipa وثبّته بالطريقة المعتادة.\n"
            "زر تحديث الآن داخل التطبيق يفتح TrollStore لتنزيل وتثبيت أحدث نسخة مباشرة. فعّل URL Scheme Enabled في إعدادات TrollStore.\n",
            encoding="utf-8",
        )
        gh("release", "create", tag, *assets, "--repo", repo, "--target", sha,
           "--title", f"صلاتي {version} ({build})", "--notes-file", str(notes), "--latest")
    print(f"Published: https://github.com/{repo}/releases/tag/{tag}")


if __name__ == "__main__":
    main()
