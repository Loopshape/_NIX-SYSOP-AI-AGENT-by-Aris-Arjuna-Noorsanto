#!/bin/env python3

import requests
import json

# Configuration for your local Ollama instance
OLLAMA_HOST = "http://localhost:11434"

def send_prompt_to_ollama(prompt: str, model: str = "core code loop 2244 coin", stream: bool = False) -> str:
    """
    Sends a prompt to a specified Ollama model and returns the response.
    
    Args:
        prompt (str): The text prompt to send to the model.
        model (str): The name of the Ollama model to use (e.g., "llama2", "mistral").
        stream (bool): If True, streams the response tokens. Otherwise, waits for full response.
                       Note: Streaming logic is more complex and not fully implemented here for brevity.
    
    Returns:
        str: The model's response.
    """
    url = f"{OLLAMA_HOST}/api/generate"
    headers = {"Content-Type": "application/json"}
    data = {
        "model": model,
        "prompt": prompt,
        "stream": stream,
        "options": {
            "temperature": 0.7,
            "top_p": 0.9
        }
    }

    try:
        print(f"Sending prompt to model '{model}'...")
        response = requests.post(url, headers=headers, data=json.dumps(data))
        response.raise_for_status()  # Raise an exception for HTTP errors (4xx or 5xx)

        if stream:
            # For streaming, you'd typically iterate over response.iter_lines()
            # and parse each JSON chunk. For simplicity, we'll just get the full text.
            full_response_text = ""
            for line in response.iter_lines():
                if line:
                    try:
                        json_response = json.loads(line.decode('utf-8'))
                        full_response_text += json_response.get("response", "")
                    except json.JSONDecodeError:
                        pass # Ignore non-JSON lines
            return full_response_text.strip()
        else:
            json_response = response.json()
            return json_response.get("response", "").strip()

    except requests.exceptions.ConnectionError:
        return f"Error: Could not connect to Ollama at {OLLAMA_HOST}. Is Ollama running?"
    except requests.exceptions.RequestException as e:
        return f"Error during API request: {e}"
    except Exception as e:
        return f"An unexpected error occurred: {e}"

def list_ollama_models() -> list:
    """
    Lists the available Ollama models.
    
    Returns:
        list: A list of dictionaries, each representing an available model.
    """
    url = f"{OLLAMA_HOST}/api/tags"
    try:
        print("Listing available Ollama models...")
        response = requests.get(url)
        response.raise_for_status()
        models_data = response.json()
        return models_data.get("models", [])
    except requests.exceptions.ConnectionError:
        print(f"Error: Could not connect to Ollama at {OLLAMA_HOST}. Is Ollama running?")
        return []
    except requests.exceptions.RequestException as e:
        print(f"Error during API request: {e}")
        return []

if __name__ == "__main__":
    print("--- Ollama Python Control Example ---")

    # 1. List available models
    models = list_ollama_models()
    if models:
        print("\nAvailable Models:")
        for model_info in models:
            print(f"- {model_info['name']} (Size: {model_info['size'] / (1024**3):.2f} GB)")
        
        # Try to use the first available model, or a default if none are found
        default_model = models[0]['name'] if models else "llama2"
        print(f"\nUsing model: {default_model}")

        # 2. Send a simple prompt
        prompt1 = "What is the capital of France?"
        response1 = send_prompt_to_ollama(prompt1, model=default_model)
        print(f"\nPrompt: {prompt1}")
        print(f"Response: {response1}")

        # 3. Send a more complex prompt (e.g., for code generation)
        prompt2 = "Write a Python function to calculate the factorial of a number recursively."
        response2 = send_prompt_to_ollama(prompt2, model=default_model)
        print(f"\nPrompt: {prompt2}")
        print(f"Response:\n{response2}")

    else:
        print("\nNo Ollama models found or connection failed. Please ensure Ollama is running and models are pulled.")
        print("You can pull a model using: ollama pull llama2")
