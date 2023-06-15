import * as FS from "https://deno.land/std@0.191.0/fs/mod.ts";
import * as Path from "https://deno.land/std@0.191.0/path/mod.ts";
import * as Colors from "https://deno.land/std@0.191.0/fmt/colors.ts";
import { crypto } from "https://deno.land/std@0.191.0/crypto/crypto.ts";
import { Option, Result } from "https://deno.land/x/opt@0.1.4/mod.ts";

const HASH_ALGO = "SHA-512";

type Job = () => void | Promise<void>;
type State = { queue: Job[]; root: string | null };

const state: State = { queue: [], root: null };

function stat(
    path: string | URL,
    options: { lstat: boolean } = { lstat: false }
): Promise<Result<Deno.FileInfo, Error>> {
    return Result.await(options.lstat ? Deno.lstat(path) : Deno.stat(path));
}

async function checkHash(path: string): Promise<Option<ArrayBuffer>> {
    return (
        await Result.await(
            Deno.readFile(path).then((data) => crypto.subtle.digest(HASH_ALGO, data))
        )
    ).ok();
}

function hashMatch(h1: ArrayBuffer, h2: Option<ArrayBuffer>): boolean {
    if (h2.isNone()) {
        return false;
    }
    const d1 = new Uint8Array(h1);
    const d2 = new Uint8Array(h2.value);
    if (d1.length !== d2.length) {
        return false;
    }
    return d1.every((b, i) => b === d2[i]);
}

function resolvePath(filePath: string): string {
    return Path.resolve(...[state.root as string, filePath].filter((s) => s !== null));
}

function normaliseTextFile(data: string): Uint8Array {
    const lines = data.split("\n");
    if (lines[0].trim() === "") {
        lines.shift();
    }
    if (lines[lines.length - 1].trim() !== "") {
        lines.push("");
    }
    return new TextEncoder().encode(lines.join("\n"));
}

function run(job: Job) {
    state.queue.push(job);
}

async function poll() {
    const job = state.queue.shift();
    if (job === undefined) {
        return;
    }
    await Promise.resolve(job()).then(() => poll());
}

export function apply() {
    poll()
        .then(() => log.info("Done!"))
        .catch((error) => {
            log.error(error);
        });
}

export const log = {
    info(act: string, info?: string) {
        if (info === undefined) {
            console.log(Colors.bold(Colors.brightWhite("·")), Colors.brightBlue(act));
        } else {
            console.log(Colors.bold(Colors.brightWhite("·")), Colors.brightBlue(act), info);
        }
    },

    action(act: string, info?: string) {
        if (info === undefined) {
            console.log(Colors.bold(Colors.brightWhite("·")), Colors.brightGreen(act));
        } else {
            console.log(Colors.bold(Colors.brightWhite("·")), Colors.brightGreen(act), info);
        }
    },

    noAction(act: string, info?: string) {
        if (info === undefined) {
            console.log(Colors.bold(Colors.brightWhite("·")), Colors.dim(Colors.white(act)));
        } else {
            console.log(
                Colors.bold(Colors.brightWhite("·")),
                Colors.dim(Colors.white(act)),
                Colors.dim(Colors.white(info))
            );
        }
    },

    error(e: Error) {
        console.error(Colors.bold(Colors.brightRed("ERROR:")), e.stack);
    },
};

export const root = {
    set(rootPath: string) {
        run(() => {
            state.root = Path.resolve(rootPath);
            log.info("Root", state.root);
        });
    },

    home() {
        const home = Deno.env.get("HOME");
        if (home === undefined) {
            throw new Error("$HOME not set.");
        }
        root.set(home);
    },

    config() {
        let xdgConfigHome = Deno.env.get("XDG_CONFIG_HOME");
        if (xdgConfigHome === undefined || xdgConfigHome === "") {
            const home = Deno.env.get("HOME");
            if (home === undefined) {
                throw new Error("$HOME not set.");
            }
            xdgConfigHome = Path.resolve(home, ".config");
        }
        root.set(xdgConfigHome);
    },
};

export const file = {
    exec(filePath: string) {
        run(async () => {
            const rPath = resolvePath(filePath);
            const fileInfo = await stat(rPath);
            if (fileInfo.isErr()) {
                throw fileInfo.value;
            }
            if (fileInfo.value.mode! & 0o100) {
                log.noAction("chmod +x", filePath);
                return;
            }
            log.action("chmod +x", filePath);
            await Deno.chmod(rPath, fileInfo.value.mode! | 0o100);
        });
    },

    text(filePath: string, contents: string) {
        run(async () => {
            const rPath = resolvePath(filePath);
            const data = normaliseTextFile(contents);
            const [sourceHash, targetHash] = await Promise.all([
                await crypto.subtle.digest(HASH_ALGO, data),
                await checkHash(rPath),
            ]);
            if (hashMatch(sourceHash, targetHash)) {
                log.noAction("Write", filePath);
                return;
            }
            log.action("Write", filePath);
            await FS.ensureFile(rPath);
            await Deno.writeFile(rPath, new Uint8Array(data));
        });
    },

    script(filePath: string, contents: string) {
        file.text(filePath, contents);
        file.exec(filePath);
    },
};

export function link(linkName: string, target: string) {
    run(async () => {
        const linkPath = resolvePath(linkName);
        const linkInfo = await stat(linkPath, { lstat: true });
        if (linkInfo.isErr()) {
            // Path does not exist; create it.
            log.action("Link:", `${linkPath} → ${target}`);
            await FS.ensureDir(Path.dirname(linkPath));
            await Deno.symlink(target, linkPath);
            return;
        }
        if (!linkInfo.value.isSymlink) {
            // Path exists but isn't a symlink; backup and create.
            log.action("Link:", `${linkPath} → ${target}`);
            await Deno.rename(linkPath, `${linkPath}.old`);
            await Deno.symlink(target, linkPath);
            return;
        }
        // Path exists and is a symlink; ensure it's the right one.
        const currentTarget = await Deno.readLink(linkPath);
        if (currentTarget === target) {
            log.noAction("Link:", `${linkPath} → ${target}`);
            return;
        }
        log.action("Link:", `${linkPath} → ${target}`);
        await Deno.remove(linkPath);
        await Deno.symlink(target, linkPath);
    });
}
