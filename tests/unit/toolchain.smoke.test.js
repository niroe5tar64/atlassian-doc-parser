import { describe, expect, it } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

describe("toolchain smoke", () => {
  it("runs under bun test", () => {
    expect(1 + 1).toBe(2);
  });

  it("loads a fixture pair", () => {
    const fixtureDir = join(process.cwd(), "tests", "fixtures", "00_smoke");
    const inputPath = join(fixtureDir, "input.xml");
    const expectedPath = join(fixtureDir, "expected.md");

    expect(existsSync(inputPath)).toBe(true);
    expect(existsSync(expectedPath)).toBe(true);

    const xml = readFileSync(inputPath, "utf8").trim();
    const markdown = readFileSync(expectedPath, "utf8").trim();

    expect(xml).toContain("<p>");
    expect(markdown.length).toBeGreaterThan(0);
  });
});
