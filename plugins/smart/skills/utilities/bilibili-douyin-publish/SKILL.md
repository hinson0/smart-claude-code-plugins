---
name: bilibili-douyin-publish
description: Prepare video metadata and covers, publish finished videos to Bilibili or Douyin, and verify each platform's actual result.
disable-model-invocation: true
---

# Bilibili and Douyin Publishing

## Scope and authorization

- Select Bilibili, Douyin, or both from the current request. Do not expand the destination scope.
- Preparing publishing materials creates local artifacts only; do not upload or submit.
- Uploading a draft permits uploading, filling fields, and saving a draft, but not final publication.
- An explicit request to publish authorizes submission after checks. Reuse that authorization rather than asking again.
- Invoking or creating this skill, or having published previously, does not itself authorize publication now.
- If authorization is unclear, finish local materials before asking about submission. Resolve account or video-version ambiguity from context first; ask only if it remains.
- Follow the current project's AGENTS.md and pipeline requirements. For an existing OpenMontage production, read its publish-stage contract and honor its gates. Publishing a finished video does not restart video production.

## 1. Identify the video and materials

Use the conversation and project artifacts to identify the final video, destinations, account, and publishing mode. Reuse approved copy and covers. Do not select an older version from its filename alone.

Check file existence, duration, orientation, audio, and subtitles. Use ffprobe and sample playback when needed. Preserve the user's landscape or portrait choice; Douyin does not imply converting to portrait. Route editing or replacement narration back to the appropriate production workflow.

Store materials in the project's `publish/` directory. In OpenMontage use `projects/<project-id>/publish/`; elsewhere use the video's working directory.

Save a publishing-copy Markdown file with one section per platform:

- Absolute video path, account display name, and immediate or scheduled publication.
- Title, description, tags or topics.
- Cover paths, source links, and other fields required by the page.

Bilibili copy can explain the problem, approach, and result. Douyin copy can be shorter and lead with the video's appeal. Choose relevant tags from the actual content; do not copy historical topics or repository links. Do not invent celebrity endorsements, quotations, or results.

## 2. Open the creator center and inspect covers

Discover available publishing tools first. Prefer a sufficient connector; otherwise use browser tools. The historical successful route used signed-in Chrome. Honor the user's chosen browser.

Follow the browser tool's own documentation and supported interfaces. Locate controls from current page text, controls, and screenshots, never stale coordinates or guessed selectors. Reuse an existing creator-center tab when possible; otherwise enter through the platform's official site.

Check the active account. Ask the user to complete expired login or CAPTCHA verification, then resume. Do not read or save cookies, passwords, or tokens.

Use the current upload page to verify video limits, title length, cover ratios, and required fields. Consult official help only when the page does not provide them. Historical experience is not a current platform specification.

Cover history and checks:

- On 2026-10-18, Douyin's page used 4:3 landscape and 3:4 portrait covers. Earlier 16:9 and 9:16 covers cropped text. Recheck these historical ratios at execution time.
- Materials from 2026-10-19 used a 16:9 Bilibili cover and a 3:4 Douyin cover. Do not infer requirements for every cover slot from this example.
- Treat video orientation separately from cover ratio; a landscape video may need a portrait cover.
- Inspect text, people, and the subject in the actual crop preview. Keep margins; checking the source image alone is insufficient.
- Inspect each cover slot that the page exposes. Save replacements and reopen the preview to verify them.

Reuse suitable existing covers. If images need generation or editing, use an available image skill and its tool and authorization rules. Do not change the video as a side effect.

## 3. Submit to Bilibili

1. Open video submission in the official creator center.
2. Upload the verified final video and wait for upload and page processing to finish.
3. Fill the title, description, tags, and cover.
4. Choose a category based on the content and declare original or reposted content according to its real source. Ask if source facts are missing.
5. Use links supplied or verified for this task when adding repository or reference links.
6. Verify the saved fields, video file, crop, account, and publishing mode.
7. Save a draft or submit according to authorization.
8. Read the result. The historical success message meant submission succeeded. Open submission management to match the entry and read its current status.

Submission success proves receipt, not public availability. Do not call a pending-review video public. Record an available submission ID, work URL, or management URL; never construct an unverified URL.

## 4. Publish to Douyin

1. Open video publishing in the official creator center.
2. Upload the verified final video and wait for upload and page processing to finish.
3. Fill the title or description fields exposed by the page and add relevant topics.
4. Select and save covers, checking every actual landscape or portrait cover slot.
5. Complete source, AI-content, or other declarations truthfully. Consult asset records when uncertain.
6. Check account, visibility, and publishing mode. For scheduling, establish the date, time, and page timezone; never silently switch to immediate publication.
7. Save a draft or publish according to authorization.
8. Return to work management, match the title, thumbnail, and time, and read the actual status.

Historical success evidence was a work-management entry marked published. Completing an upload or clicking publish alone does not prove success.

## 5. Verify results and prevent duplicates

After a timeout, blank page, or tool disconnect following submission, inspect submission or work management first. If the entry exists, continue verification without submitting again.

Retry only when submission clearly failed and management contains no matching entry. If the outcome remains ambiguous, record it as unknown, stop submitting, and tell the user. Never publish a test video solely to verify this workflow.

Track the platforms independently. Preserve one platform's success if the other fails. Continue an authorized platform that does not depend on the failure. Retry only unfinished destinations, never successful ones.

Save a publishing-results Markdown file with one section per platform:

- Account, video path, title, submission time, and timezone.
- Draft, submitted, under review, published, failed, or unknown status.
- Verbatim page status, available submission ID, and links.
- Screenshot paths for the success page or matching management entry. If screenshots are unsupported, record page-text evidence and that limitation.
- Failure cause and any remaining user action.

Capture only necessary result areas, without exporting login information. Reuse the evidence directory without overwriting previous publication records.

Report each platform's actual result first, then work or evidence links. State pending publication, review rejection, login blockers, and unknown outcomes explicitly. Unless separately arranged, report the current review status without promising background monitoring.
