import asyncio
from dotenv import load_dotenv

from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from langchain.agents import AgentExecutor, create_openai_tools_agent

from mcp_client_langchain.clients import StreamableHttpMcpClient

# .env 파일에서 환경 변수 로드 (OPENAI_API_KEY)
load_dotenv()

async def main():
    """
    MCP 서버에 Streamable HTTP로 연결하고 LangChain 에이전트를 사용하여 도구를 실행하는 메인 함수
    """
    # 1. MCP 서버에 Streamable HTTP 클라이언트로 연결합니다.
    #    서버가 기본값(http://127.0.0.1:8000/mcp)으로 실행 중이라고 가정합니다.
    mcp_http_url = "http://127.0.0.1:8000/mcp"
    print(f"Connecting to MCP server at {mcp_http_url}...")
    
    # StreamableHttpMcpClient는 비동기적으로 초기화해야 합니다.
    mcp_client = await StreamableHttpMcpClient.create(mcp_http_url)
    
    # 2. MCP 서버로부터 LangChain 호환 도구를 가져옵니다.
    tools = mcp_client.get_tools()
    tool_names = ", ".join([tool.name for tool in tools])
    print(f"Successfully connected. Available tools: {tool_names}")

    # 3. LangChain 에이전트를 설정합니다.
    #    여기서는 OpenAI의 함수 호출(function-calling) 모델을 사용합니다.
    llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)

    # 에이전트가 따라야 할 프롬프트를 정의합니다.
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful assistant that can interact with Elasticsearch."),
        ("user", "{input}"),
        # 'agent_scratchpad'는 에이전트의 중간 작업 단계를 저장하는 곳입니다.
        ("placeholder", "{agent_scratchpad}"),
    ])

    # OpenAI 도구 에이전트를 생성합니다.
    agent = create_openai_tools_agent(llm, tools, prompt)

    # 에이전트 실행기(AgentExecutor)를 생성합니다.
    agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

    # 4. 에이전트를 실행하여 MCP 도구를 사용하도록 유도하는 질문을 합니다.
    #    'search_documents' 도구를 사용하도록 유도합니다.
    #    (테스트를 위해 Kibana 샘플 로그 데이터가 있다고 가정합니다.)
    print("\n--- Invoking agent to search documents ---")
    question = "Search for documents containing the word 'error' in the '.kibana_sample_data_logs' index."
    response = await agent_executor.ainvoke({"input": question})

    print("\n--- Agent's final answer ---")
    print(response["output"])
    
    # 5. 클라이언트 연결을 종료합니다.
    await mcp_client.close()
    print("\nConnection closed.")


if __name__ == "__main__":
    # Python 3.7+ 에서 비동기 main 함수를 실행합니다.
    asyncio.run(main())
