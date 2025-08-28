# 1. 기반 이미지 설정 (Alpine Linux로 가볍게 시작)
FROM python:3.10-alpine

# 2. 작업 디렉토리 설정
WORKDIR /app
# 3. 의존성 및 메타데이터 정의 파일들 먼저 복사 (Docker 캐시 효율 극대화)
COPY . .

# 4. 보안을 위해 비-루트 사용자 생성
# 파일 복사 및 설치는 root 권한으로 진행하고, 실행만 appuser로 전환합니다.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 5. 의존성 설치 (빌드용 패키지는 설치 후 즉시 제거)
# 'pip install .' 명령어는 pyproject.toml을 읽어 프로젝트와 의존성을 모두 설치합니다.
RUN apk add --no-cache --virtual .build-deps gcc musl-dev && \
    pip install --no-cache-dir . && \
    apk del .build-deps

# 7. 생성한 비-루트 사용자로 전환 (보안 강화)
USER appuser

# 8. 런타임에 외부에서 주입될 환경 변수들을 정의합니다.
ENV ELASTIC_USERNAME="" \
    ELASTIC_PASSWORD="" \
    ELASTIC_HOST=""

# 9. 서버 포트를 외부에 노출합니다.
EXPOSE 8080

# 10. 컨테이너 실행 시 서버를 시작하는 명령입니다.
# python -m <모듈> 형식으로 실행하는 것이 안정적입니다.
CMD ["python", "-m", "src.server", "elasticsearch-mcp-server", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8080"]