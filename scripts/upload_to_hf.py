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
from pathlib import Path
from huggingface_hub import login, HfApi, logout
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
        
        self.api = None
        self._login()
    
    def _login(self):
        """Login to HuggingFace"""
        try:
            # Check if already logged in
            api = HfApi(endpoint=self.hf_endpoint)
            user_info = api.whoami(token=self.hf_token)
            logger.info(f"✅ Logged in as: {user_info.get('name', 'Unknown')}")
        except Exception as e:
            logger.warning(f"Login check failed, attempting login: {e}")
        
        try:
            login(token=self.hf_token)
            self.api = HfApi(endpoint=self.hf_endpoint, token=self.hf_token)
            logger.info(f"✅ Successfully logged in to {self.hf_endpoint}")
        except Exception as e:
            logger.error(f"❌ Login failed: {e}")
            raise
    
    def upload_file(self, repo_id: str, local_path: str, path_in_repo: Optional[str] = None):
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
        logger.info(f"📤 Uploading {os.path.basename(local_path)} ({file_size:.2f} MB) to {repo_id}/{path_in_repo}")
        
        try:
            self.api.upload_file(
                path_or_fileobj=local_path,
                repo_id=repo_id,
                repo_type='dataset',
                path_in_repo=path_in_repo,
                token=self.hf_token
            )
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
            path_in_repo=args.path_in_repo
        )
        logger.info("🎉 Upload completed successfully!")
    except Exception as e:
        logger.error(f"❌ Upload failed: {e}")
        sys.exit(1)
    finally:
        try:
            logout()
        except:
            pass


if __name__ == "__main__":
    main()

