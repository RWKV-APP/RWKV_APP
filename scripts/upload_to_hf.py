#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Upload build artifacts to HuggingFace dataset repository
Supports HF mirror endpoints for China mainland
"""

import os
import sys
import argparse
import logging
import hashlib
from huggingface_hub import HfApi
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)


class HFUploader:
    """HuggingFace uploader with mirror support"""
    
    def __init__(self, hf_token: str, hf_endpoint: Optional[str] = None):
        """
        Initialize HF uploader
        
        Args:
            hf_token: HuggingFace token
            hf_endpoint: HF endpoint URL (defaults to https://huggingface.co - mirrors sync automatically)
        """
        self.hf_token = hf_token
        # Use official HuggingFace endpoint - mirrors will sync automatically
        self.hf_endpoint = hf_endpoint or os.getenv("HF_ENDPOINT", "https://huggingface.co")
        
        # Set environment variables for downstream libraries
        os.environ["HF_ENDPOINT"] = self.hf_endpoint
        os.environ["HUGGINGFACE_HUB_ENDPOINT"] = self.hf_endpoint
        
        # Avoid whoami/login here because HuggingFace rate-limits /whoami-v2
        # aggressively. The upload request below validates the token directly.
        self.api = HfApi(endpoint=self.hf_endpoint, token=self.hf_token)
        logger.info(f"✅ Configured HuggingFace API client for {self.hf_endpoint}")
    
    def upload_file(self, repo_id: str, local_path: str, path_in_repo: Optional[str] = None, verify_package: bool = False):
        """
        Upload a file to HuggingFace dataset repository
        
        Args:
            repo_id: HF repository ID (e.g., 'username/dataset-name')
            local_path: Local file path to upload
            path_in_repo: Path in the repository (default: filename)
        """
        if not os.path.exists(local_path):
            raise FileNotFoundError(f"File not found: {local_path}")
        
        if path_in_repo is None:
            path_in_repo = os.path.basename(local_path)
        
        file_size = os.path.getsize(local_path) / (1024 * 1024)  # MB
        digest = hashlib.sha256()
        with open(local_path, 'rb') as stream:
            for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b''):
                digest.update(chunk)
        expected = (os.path.getsize(local_path), digest.hexdigest())
        anonymous = HfApi(endpoint=self.hf_endpoint, token=False)
        def verify(revision='main'):
            rows = anonymous.get_paths_info(repo_id, paths=[path_in_repo], repo_type='dataset', revision=revision, token=False)
            if not rows:
                return False
            row = rows[0]
            # Application packages use LFS; a missing digest is not proof of identity.
            remote_digest = getattr(getattr(row, 'lfs', None), 'sha256', None)
            if (row.size, remote_digest) != expected:
                raise ValueError(f'Remote Hugging Face artifact differs or lacks a SHA-256: {path_in_repo}; refusing replacement')
            return True
        if verify_package and verify():
            logger.info('Existing Hugging Face artifact anonymously verified; no replacement needed')
            return True
        logger.info(f"📤 Uploading {os.path.basename(local_path)} ({file_size:.2f} MB) to {repo_id}/{path_in_repo}")
        
        try:
            commit = self.api.upload_file(
                path_or_fileobj=local_path,
                repo_id=repo_id,
                repo_type='dataset',
                path_in_repo=path_in_repo,
                token=self.hf_token
            )
            if verify_package and not verify(commit.oid):
                raise ValueError('Uploaded Hugging Face artifact is not anonymously visible')
            logger.info(f"✅ Successfully uploaded to {repo_id}/{path_in_repo}")
            return True
        except Exception as e:
            logger.error(f"❌ Upload failed: {e}")
            raise
    
    def upload_multiple_files(self, repo_id: str, files: list, base_path_in_repo: Optional[str] = None):
        """
        Upload multiple files to HuggingFace
        
        Args:
            repo_id: HF repository ID
            files: List of local file paths
            base_path_in_repo: Base path in repo (optional)
        """
        results = []
        for file_path in files:
            if not os.path.exists(file_path):
                logger.warning(f"⚠️ File not found, skipping: {file_path}")
                continue
            
            if base_path_in_repo:
                path_in_repo = f"{base_path_in_repo}/{os.path.basename(file_path)}"
            else:
                path_in_repo = os.path.basename(file_path)
            
            try:
                self.upload_file(repo_id, file_path, path_in_repo)
                results.append((file_path, True, None))
            except Exception as e:
                results.append((file_path, False, str(e)))
        
        return results


def main():
    parser = argparse.ArgumentParser(description='Upload files to HuggingFace dataset')
    parser.add_argument('--repo-id', required=True, help='HF repository ID (e.g., username/dataset-name)')
    parser.add_argument('--file', required=True, help='Local file path to upload')
    parser.add_argument('--path-in-repo', help='Path in repository (default: filename)')
    parser.add_argument('--hf-token', help='HuggingFace token (or use HF_TOKEN env var)')
    parser.add_argument('--hf-endpoint', help='HF endpoint URL (or use HF_ENDPOINT env var, default: https://huggingface.co)')
    parser.add_argument('--verify-package', action='store_true', help='Require anonymous LFS size/SHA-256 identity and refuse replacement')
    
    args = parser.parse_args()
    
    # Get token from args or environment
    hf_token = args.hf_token or os.getenv("HF_TOKEN")
    if not hf_token:
        logger.error("❌ HuggingFace token not provided. Use --hf-token or set HF_TOKEN environment variable")
        sys.exit(1)
    
    # Get endpoint from args or environment
    hf_endpoint = args.hf_endpoint or os.getenv("HF_ENDPOINT")
    
    try:
        uploader = HFUploader(hf_token, hf_endpoint)
        uploader.upload_file(
            repo_id=args.repo_id,
            local_path=args.file,
            path_in_repo=args.path_in_repo,
            verify_package=args.verify_package,
        )
        logger.info("🎉 Upload completed successfully!")
    except Exception as e:
        logger.error(f"❌ Upload failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
