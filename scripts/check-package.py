import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
MOON = shutil.which("moon")


def run(*args, cwd=ROOT):
    subprocess.run([MOON, *args], cwd=cwd, check=True)


def main():
    # 从真正的归档创建隔离工作区，消费者只能使用公开接口。
    manifest = (ROOT / "moon.mod").read_text(encoding="utf-8")
    version = re.search(r'version\s*=\s*"([^"]+)"', manifest).group(1)
    run("package")
    archive = ROOT / "_build" / "publish" / f"prowk-moon-emmet-{version}.zip"
    workspace = Path(tempfile.mkdtemp(prefix="consumer-", dir=archive.parent))
    library = workspace / "library"
    consumer = workspace / "consumer"
    with ZipFile(archive) as package:
        names = package.namelist()
        for name in names:
            path = Path(name)
            assert not path.is_absolute() and ".." not in path.parts, name
            assert not any(part in {"research", "node_modules", "_build"} for part in path.parts), name
            assert not any(ord(char) > 127 for char in name), name
        for required in ["moon.mod", "moon.pkg", "LICENSE", "README.md", "snippets.mbt", "docs/api.md"]:
            assert required in names, required
        package.extractall(library)
    consumer.mkdir()
    (workspace / "moon.work").write_text('members = ["library", "consumer"]\n', encoding="utf-8")
    (consumer / "moon.mod").write_text(
        f'name = "local/consumer"\nimport {{ "prowk/moon-emmet@{version}" }}\n', encoding="utf-8")
    (consumer / "moon.pkg").write_text('import { "prowk/moon-emmet" @engine } for "test"\n', encoding="utf-8")
    (consumer / "consumer_test.mbt").write_text('''///|
test "从发布包使用公开接口" {
  let options = @engine.Options::new(snippets=[@engine.Snippet::new("box", "section")])
  assert_eq(@engine.expand_with_options("box>p{hello}", options), Ok("<section><p>hello</p></section>"))
  assert_eq(@engine.expand_css("m10-20+c#fff"), Ok("margin: 10px 20px;\\ncolor: #fff;"))
  let result = @engine.expand_for_editor("a")
  guard result is Ok(value) else { fail("展开失败") }
  assert_eq(value.tabstops, [9, 11])
  let tree = @engine.parse("p*2")
  guard tree is Ok(nodes) else { fail("解析失败") }
  assert_eq(nodes[0].repeat_count, 2)
}
''', encoding="utf-8")
    run("test", "consumer", "--target", "wasm-gc", "--deny-warn", cwd=workspace)
    run("test", "consumer", "--target", "js", "--deny-warn", cwd=workspace)
    run("build", "library/bridge", "--target", "js", "--release", cwd=workspace)
    report = {"version": version, "archive": str(archive), "files": len(names),
              "consumer_targets": ["wasm-gc", "js"], "bridge_build": "passed"}
    (archive.parent / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
