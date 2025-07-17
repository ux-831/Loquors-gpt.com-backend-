# app.py

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import os # Environment variables को एक्सेस करने के लिए

app = Flask(__name__)

# --- CORS कॉन्फ़िगरेशन (बहुत ज़रूरी!) ---
# 'https://YOUR_GITHUB_USERNAME.github.io' को अपने GitHub Pages के असली URL से बदलें।
CORS(app, origins="https://YOUR_GITHUB_USERNAME.github.io")

# --- Google Gemini API कॉन्फ़िगरेशन ---
# Render पर एक Environment Variable के रूप में अपनी Google API Key सेट करेंगे।
GOOGLE_API_KEY = os.environ.get("GOOGLE_API_KEY") # <--- यह लाइन API Key को Environment Variable से पढ़ती है।

# Gemini Pro टेक्स्ट जनरेशन मॉडल का API एंडपॉइंट URL
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

def get_gemini_response(prompt):
    if not GOOGLE_API_KEY:
        raise ValueError("Google API Key is not set in environment variables.") # <--- यदि KEY नहीं मिली तो एरर

    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ]
    }
    
    params = {"key": GOOGLE_API_KEY} # API Key को URL पैरामीटर के रूप में भेजा जाता है

    try:
        response = requests.post(GEMINI_API_URL, headers=headers, json=payload, params=params, timeout=60)
        response.raise_for_status() 
        
        data = response.json()
        
        if "candidates" in data and data["candidates"]:
            candidate = data["candidates"][0]
            if "parts" in candidate and candidate["parts"]:
                return candidate["parts"][0]["text"]
        return "Sorry, I received an empty or unexpected response from Google Gemini."

    except requests.exceptions.RequestException as e:
        print(f"Error calling Google Gemini API: {e}")
        return "Sorry, I couldn't connect to the AI model. Please try again later."
    except Exception as e:
        print(f"An unexpected error occurred with Google Gemini: {e}")
        return "An internal error occurred while processing your request."

@app.route("/api/chat-with-ai", methods=["POST"]) # यह आपके Backend का API एंडपॉइंट है
def chat_with_ai():
    data = request.json
    user_prompt = data.get("prompt", "")

    if not user_prompt:
        return jsonify({"success": False, "message": "No prompt provided"}), 400

    try:
        ai_response = get_gemini_response(user_prompt)
        return jsonify({"success": True, "aiResponse": ai_response})
    except ValueError as e:
        return jsonify({"success": False, "message": str(e)}), 500
    except Exception as e:
        return jsonify({"success": False, "message": "Failed to get AI response"}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
