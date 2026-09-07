# Knowledge base
KNOWLEDGE_DIR = "knowledge/sample_docs"

# Text chunking
CHUNK_SIZE = 500
CHUNK_OVERLAP = 50

# Number of relevant documents to retrieve
TOP_K = 3

# Sentence Transformer embedding model
EMBEDDING_MODEL = "all-MiniLM-L6-v2"

# Local Ollama model
OLLAMA_MODEL = "qwen2.5-coder:7b"

# Ollama API URL
OLLAMA_URL = "http://localhost:11434/api/generate"

# FAISS index directory
FAISS_INDEX_DIR = "knowledge/faiss_index"
