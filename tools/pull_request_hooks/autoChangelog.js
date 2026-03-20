import { parseChangelog } from "./changelogParser.js";

const safeYml = (string) =>
	string.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n");

export function changelogToYml(changelog, login) {
	const author = changelog.author || login;
	const ymlLines = [];

	ymlLines.push(`author: "${safeYml(author)}"`);
	ymlLines.push(`delete-after: True`);
	ymlLines.push(`changes:`);

	for (const change of changelog.changes) {
		ymlLines.push(
			`  - ${change.type.changelogKey}: "${safeYml(change.description)}"`
		);
	}

	return ymlLines.join("\n");
}

export function buildAutoChangelogFile({ body, login, prNumber }) {
	const changelog = parseChangelog(body ?? "");
	if (!changelog || changelog.changes.length === 0) {
		return undefined;
	}

	return {
		path: `html/changelogs/AutoChangeLog-pr-${prNumber}.yml`,
		contents: changelogToYml(changelog, login),
	};
}

export async function processAutoChangelog({ github, context }) {
	const autoChangelog = buildAutoChangelogFile({
		body: context.payload.pull_request.body,
		login: context.payload.pull_request.user.login,
		prNumber: context.payload.pull_request.number,
	});
	if (!autoChangelog) {
		console.log("no changelog found");
		return;
	}

	await github.rest.repos.createOrUpdateFileContents({
		owner: context.repo.owner,
		repo: context.repo.repo,
		path: autoChangelog.path,
		message: `Automatic changelog for PR #${context.payload.pull_request.number} [ci skip]`,
		content: Buffer.from(autoChangelog.contents).toString("base64"),
	});
}
