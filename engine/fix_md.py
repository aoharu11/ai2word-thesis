#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI 마크다운 원고 전처리기 (비파괴 개선판)

원본 입력 파일을 절대 수정하지 않습니다.
수정된 내용은 별도 출력 파일로 저장되며, 원본은 그대로 유지됩니다.

핵심 원칙:
  1. LaTeX 수식 블록($$, \[ \], $..., \(...\))은 어떤 변환도 적용되지 않음
  2. 코드 블록(```...```)은 어떤 변환도 적용되지 않음
  3. 마크다운 제목(#, ##, ###)은 보존됨 (Word 스타일 매핑에 필요)
  4. 입력 파일은 읽기 전용으로만 사용, 출력 파일은 새로 생성

사용법:
    python fix_md.py [입력파일.md] [출력파일.md]
    (입력 파일 생략 시 [2]원고입력.md, 출력 파일 생략 시 자동 생성)
"""

import re
import sys
import os

# Windows 콘솔에서 한국어 출력이 깨지지 않도록 인코딩 강제 설정
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
if hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def protect_blocks(text):
    """
    수식 블록과 코드 블록을 자리표시자로 치환해 보호합니다.
    보호된 블록은 이후 어떤 텍스트 변환도 적용되지 않습니다.
    """
    blocks = []
    counter = [0]

    def replacer(match):
        blocks.append(match.group(0))
        key = f'__BLOCK{counter[0]}__'
        counter[0] += 1
        return key

    # 1. $$...$$ 블록 수식 (Display math)
    text = re.sub(r'\$\$.*?\$\$', replacer, text, flags=re.DOTALL)
    # 2. \[...\] 블록 수식
    text = re.sub(r'\\\[.*?\\\]', replacer, text, flags=re.DOTALL)
    # 3. \(...\) 인라인 수식
    text = re.sub(r'\\\(.*?\\\)', replacer, text)
    # 4. $...$ 인라인 수식 ($$ 제외, 역슬래시 이스케이프 허용)
    text = re.sub(r'(?<!\$)\$(?!\$)(?:\\.|[^$\\])+\$(?!\$)', replacer, text)
    # 5. ```...``` 코드 블록
    text = re.sub(r'```.*?```', replacer, text, flags=re.DOTALL)

    return text, blocks


def restore_blocks(text, blocks):
    """자리표시자를 원래 블록 내용으로 복원합니다."""
    for i, block in enumerate(blocks):
        text = text.replace(f'__BLOCK{i}__', block)
    return text


def fix_common_issues(text):
    """
    수식/코드 블록 밖에서 흔히 발생하는 AI 마크다운 오류만 최소한 수정합니다.
    파괴적인 변환(줄바꿈 제거, 제목 삭제 등)은 전혀 하지 않습니다.
    """
    # 줄 시작의 \# 또는 \\# 를 # 로 복원 (AI가 제목 앞에 백슬래시를 붙이는 경우)
    text = re.sub(r'(?m)^[ \t]*\\\\#', '#', text)
    text = re.sub(r'(?m)^[ \t]*\\#', '#', text)

    return text


def process(input_path, output_path=None):
    if not os.path.exists(input_path):
        print(f"[오류] 파일을 찾을 수 없습니다: {input_path}")
        return False

    if output_path is None:
        base = os.path.splitext(input_path)[0]
        output_path = base + '_고침.md'

    # 입력 파일과 출력 파일이 같으면 덮어쓰기 방지
    if os.path.abspath(input_path) == os.path.abspath(output_path):
        print(f"[오류] 입력 파일과 출력 파일이 같습니다: {input_path}")
        return False

    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"[오류] 입력 파일 읽기 실패: {e}")
        return False

    # 보호 블록 추출
    content, blocks = protect_blocks(content)

    # 수식 밖 일반적인 수정만 적용
    content = fix_common_issues(content)

    # 보호 블록 복원
    content = restore_blocks(content, blocks)

    # 출력 파일 저장 (입력 파일과는 별도)
    try:
        out_dir = os.path.dirname(os.path.abspath(output_path))
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
    except Exception as e:
        print(f"[오류] 출력 파일 쓰기 실패: {e}")
        return False

    print(f"[완료] 전처리된 원고: {output_path}")
    return True


if __name__ == '__main__':
    input_file = sys.argv[1] if len(sys.argv) > 1 else '[2]원고입력.md'
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    success = process(input_file, output_file)
    sys.exit(0 if success else 1)
