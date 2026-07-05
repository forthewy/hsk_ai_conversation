# HSK AI Chat

HSK1 학습자를 위한 AI 기반 중국어 회화 학습 앱입니다.

## 프로젝트 목적

초급 학습자는 실생활에서 배운것을 활용하기 어렵습니다. 
AI 가 실수하는 것처럼, 상대방이 너무 어려운 단어,문장을 사용하거나 배운적 없는 단어,주제가 쏟아지기 때문입니다.

본 프로젝트는 HSK1 수준에 맞춘 대화 흐름과 AI를 결합하여
AI를 제어하여 초급학습자를 위한 챗봇으로 활용할수 있습니다.

## Tech Stack

- Flutter
- Dart
- Hive
- Gemini API
- Ollama
- JSON

<img width="250" height="360" alt="wordbook" src="https://github.com/user-attachments/assets/f7c13a51-3e93-4d5f-969c-ab0ddbc02c38" />


## 특징
- HSK 레벨 선택
- NPC 기반 회화 학습
- FSM 기반 대화 시스템
   - 대화 흐름의 일관성 및 LLM의 주제 이탈 방지
- Rule-based 입력 검증
   - 사용자 입력을 규칙 기반으로 분석하여 첫 인사 등 공통 패턴은 AI 호출 없이 처리하고, 필요한 경우에만 LLM을 호출하도록 설계했습니다.
- Gemini / Ollama 지원
  - AI Provider를 통해 Gemini와 Ollama를 동일한 인터페이스로 사용할 수 있도록 설계하여 개발 테스트시 드는 AI 비용 축소. 
- 단어장 시스템
  - HSK 레벨별 단어를 확인하고 암기 여부를 관리할 수 있습니다.

## AI 호출 및 답변 생성 구조

Player Input
    ↓
Rule-based Validation
    ↓
Memory Extraction
    ↓
FSM State Transition
    ↓
Prompt Builder
    ↓
AI (Gemini / Ollama)
    ↓
NPC Response


## 업데이트 계획
- 음성 인식 추가 -> 실제 대화하는 느낌의 학습

- 
