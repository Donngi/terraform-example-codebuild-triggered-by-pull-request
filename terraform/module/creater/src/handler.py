import os
from logging import getLogger
from typing import Any

import boto3
from mypy_boto3_codebuild import CodeBuildClient
from mypy_boto3_codebuild.type_defs import CreateProjectOutputTypeDef, StartBuildOutputTypeDef
from mypy_boto3_codestar_notifications import CodeStarNotificationsClient
from mypy_boto3_codestar_notifications.type_defs import CreateNotificationRuleResultTypeDef
from mypy_boto3_dynamodb.service_resource import Table

logger = getLogger(__name__)
logger.setLevel(os.getenv("LOG_LEVEL", "WARNING"))


def create_codebuild(
    client: CodeBuildClient,
    repository_name: str,
    branch_name: str,
    pull_request_id: str,
    repository_region: str,
    buildspec_path: str,
    iam_role_arn: str,
) -> CreateProjectOutputTypeDef:
    # To change CodeBuild settings, please edit here.

    branch_name_escaped = branch_name.replace("/", "-")

    return client.create_project(
        name=f"ci-pull-request-{repository_name}-{branch_name_escaped}-id-{pull_request_id}",
        description=f"Project for {repository_name} - {branch_name}: pull request id = {pull_request_id}",
        source={
            "type": "CODECOMMIT",
            "location": f"https://git-codecommit.{repository_region}.amazonaws.com/v1/repos/{repository_name}",
            "buildspec": buildspec_path,
        },
        sourceVersion=f"refs/heads/{branch_name}",
        artifacts={
            "type": "NO_ARTIFACTS",
        },
        environment={
            "type": "LINUX_CONTAINER",
            "image": "aws/codebuild/amazonlinux2-x86_64-standard:3.0",
            "computeType": "BUILD_GENERAL1_SMALL",
            "environmentVariables": [
                {"name": "REPOSITORY_NAME", "value": repository_name, "type": "PLAINTEXT"},
                {"name": "BRANCH_NAME", "value": branch_name, "type": "PLAINTEXT"},
                {"name": "PULL_REQUEST_ID", "value": pull_request_id, "type": "PLAINTEXT"},
            ],
            "privilegedMode": False,
        },
        serviceRole=iam_role_arn,
        timeoutInMinutes=30,
        logsConfig={
            "cloudWatchLogs": {
                "status": "ENABLED",
            },
        },
    )


def create_notification(
    client: CodeStarNotificationsClient,
    codebuild_arn: str,
    codebuild_project_name: str,
    sns_arn: str,
) -> CreateNotificationRuleResultTypeDef:
    return client.create_notification_rule(
        Name=codebuild_project_name,
        EventTypeIds=[
            "codebuild-project-build-state-succeeded",
            "codebuild-project-build-state-failed",
        ],
        Resource=codebuild_arn,
        Targets=[
            {"TargetType": "SNS", "TargetAddress": sns_arn},
        ],
        DetailType="FULL",
    )


def run_codebuild(client: CodeBuildClient, project_name: str) -> StartBuildOutputTypeDef:
    return client.start_build(projectName=project_name)


def is_needed_to_create_codebuild_project(
    table: Table, repository_name: str, branch_name: str
) -> bool:
    res_any = table.get_item(
        Key={"repository": repository_name, "branch": "any"},
    )
    res_branch = table.get_item(
        Key={"repository": repository_name, "branch": branch_name},
    )
    if "Item" in res_any or "Item" in res_branch:
        return False
    return True


def handle_request(event: Any, context: Any) -> None:
    logger.debug(f"event: {event}")

    repository_name = event["detail"]["repositoryNames"][0]
    branch_name = event["detail"]["sourceReference"].replace("refs/heads/", "")
    pull_request_id = event["detail"]["pullRequestId"]
    repository_region = event["region"]
    table_name = os.environ["DYNAMODB_TABLE_NAME"]
    sns_arn = os.environ["SNS_ARN"]
    buildspec_path = os.getenv(
        "BUILDSPEC_S3_PATH", ""
    )  # NOTE: If buildspec path is not set, CodeBuild uses the buildspec file located at its root directory.
    iam_role_arn_for_codebuild = os.environ["IAM_ROLE_ARN_FOR_CODEBUILD"]

    table = boto3.resource("dynamodb").Table(table_name)
    codebuild = boto3.client("codebuild")
    codestar = boto3.client("codestar-notifications")
    if is_needed_to_create_codebuild_project(table, repository_name, branch_name):
        logger.debug("Start to create CodeBuild project")
        res_create = create_codebuild(
            client=codebuild,
            repository_name=repository_name,
            branch_name=branch_name,
            pull_request_id=pull_request_id,
            repository_region=repository_region,
            buildspec_path=buildspec_path,
            iam_role_arn=iam_role_arn_for_codebuild,
        )
        logger.debug(res_create)

        logger.debug("Start to create CodeStar Notifications")
        res_create_notification = create_notification(
            client=codestar,
            codebuild_arn=res_create["project"]["arn"],
            codebuild_project_name=res_create["project"]["name"],
            sns_arn=sns_arn,
        )
        logger.debug(res_create_notification)

        logger.debug("Start to run CodeBuild project")
        res_run = run_codebuild(codebuild, res_create["project"]["name"])
        logger.debug(res_run)
    else:
        logger.debug(f"{repository_name} - branch: {branch_name} is in exclusion list")
