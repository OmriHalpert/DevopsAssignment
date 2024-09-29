import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sha_arr = []

def lambda_handler(event, context):
    response = {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {},
        "body": "{}"
    }
    
    # Extract headers and log event type
    headers = event.get('headers', {})
    event_type = headers.get('X-GitHub-Event')
    
    if not event_type:
        logger.error("No X-GitHub-Event found in headers")
        return response

    logger.info(f"Event type received: {event_type}")

    # Parse the event body to JSON
    body = json.loads(event.get('body', "{}"))
    
    # Pull request events
    if event_type == 'pull_request' and body.get('action') == 'closed':
        pr_commit_sha = body.get('pull_request', {}).get('merge_commit_sha')
        if pr_commit_sha:
            sha_arr.append(pr_commit_sha)
            logger.info(f"Stored merge commit SHA: {pr_commit_sha}")
        else:
            logger.error("No merge commit SHA found in pull request event")
    
    # Push request events
    elif event_type == 'push':
        logger.info(f"Processing push event with commits: {len(body.get('commits', []))} commits")

        for pr_commit_id in sha_arr:
            for push_commit in body.get('commits', []):
                if push_commit['id'] == pr_commit_id:
                    changed_files = push_commit.get('added', []) + push_commit.get('modified', []) + push_commit.get('removed', [])
                    logger.info(f"PR merged in repo: {body.get('repository', {}).get('name')}")
                    logger.info(f"Changed files: {changed_files}")
                    return response
        # Log if no matching commit found
        logger.info("No matching commit found in push event")

    return response
