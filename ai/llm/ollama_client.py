import requests

from ai.rag.config import OLLAMA_MODEL, OLLAMA_URL


def generate_response(prompt):
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
    }

    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=60)
        response.raise_for_status()
    except requests.exceptions.Timeout as error:
        raise RuntimeError("Ollama request timed out.") from error
    except requests.exceptions.ConnectionError as error:
        raise RuntimeError("Could not connect to the Ollama server.") from error
    except requests.exceptions.HTTPError as error:
        raise RuntimeError(f"Ollama returned an HTTP error: {error}") from error
    except requests.exceptions.RequestException as error:
        raise RuntimeError(f"Ollama request failed: {error}") from error

    try:
        data = response.json()
    except ValueError as error:
        raise RuntimeError("Ollama returned malformed JSON.") from error

    generated_text = data.get("response") if isinstance(data, dict) else None
    if not isinstance(generated_text, str):
        raise RuntimeError("Ollama response is missing the 'response' field.")
    if not generated_text.strip():
        raise RuntimeError("Ollama returned an empty response.")

    return generated_text