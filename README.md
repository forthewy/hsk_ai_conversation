# HSK AI Chat

HSK1 학습자를 위한 AI 기반 중국어 회화 학습 앱입니다.

## 프로젝트 목적

초급 학습자는 실생활에서 배운 회화를 바로 사용하기 어렵습니다.
본 프로젝트는 HSK1 수준에 맞춘 대화 흐름과 AI를 결합하여
실제 회화를 연습할 수 있도록 합니다.

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
   - Introduction → Quest 상태로 대화를 관리하여 AI가 주제에서 크게 벗어나지 않도록 설계했습니다. 각 상태는 사용자 입력과 대화 진행도에 따라 전이되며, HSK 수준에 맞는 응답을 유지합니다.
- Rule-based 입력 검증
   - 사용자 입력을 규칙 기반으로 분석하여 첫 인사 등 공통 패턴은 AI 호출 없이 처리하고, 필요한 경우에만 LLM을 호출하도록 설계했습니다.
- Gemini / Ollama 지원
  - AI Provider를 통해 Gemini와 Ollama를 동일한 인터페이스로 사용할 수 있도록 설계했습니다. 개발 환경에서는 로컬 Ollama를, 실제 서비스에서는 Gemini를 사용할 수 있습니다. 현재 노트북과 핸드폰 모두 AI 작동 되는 것을 확인했습니다.
- 단어장 시스템


## 업데이트 계획
- 음성 인식 추가 -> 실제 대화하는 느낌의 학습

- 
