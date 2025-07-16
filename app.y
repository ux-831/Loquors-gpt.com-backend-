# app.py

from flask import Flask, request, jsonify
import requests
from flask_cors import CORS # Flask-CORS लाइब्रेरी को इंपोर्ट करें

app = Flask(__name__)

# --- CORS कॉन्फ़िगरेशन (बहुत ज़रूरी!) ---
# यह आपके GitHub Pages frontend को आपके Render backend से बात करने की अनुमति देता है।
# 'https://YOUR_GITHUB_USERNAME.github.io' को अपने वास्तविक GitHub Pages URL से बदलें।
# अगर आपको अपना GitHub Pages URL नहीं पता, तो GitHub पर अपनी frontend repo सेटिंग्स में देखें।
CORS(app, origins="https://YOUR_GITHUB_USERNAME.github.io")

# अगर आपको CORS में समस्या आती है, तो आप टेस्टिंग के लिए इसे ऐसे कर सकते हैं:
# CORS(app) # यह सभी ओरिजिन से रिक्वेस्ट की अनुमति देगा (सुरक्षा के लिए अच्छा नहीं है, पर टेस्टिंग के लिए ठीक)


def get_internet_answer(query):
    # DuckDuckGo API से डेटा प्राप्त करने के लिए URL
    # 't' पैरामीटर को किसी भी पहचानकर्ता से बदल सकते हैं, जैसे 'loquors_gpt_app'
    url = f"https://api.duckduckgo.com/?q={query}&format=json&t=loquors_gpt_app"
    try:
        res = requests.get(url, timeout=10) # 10 सेकंड का टाइमआउट सेट करें
        res.raise_for_status() # यदि रिक्वेस्ट सफल नहीं होती है (जैसे 404, 500), तो एरर उठाएं
        data = res.json()

        answer = data.get("AbstractText") # मुख्य संक्षिप्त उत्तर
        if not answer and data.get("RelatedTopics"):
            if isinstance(data["RelatedTopics"], list) and data["RelatedTopics"]:
                for topic in data["RelatedTopics"]:
                    if topic.get("Text"):
                        answer = topic.get("Text")
                        break
                if not answer:
                    answer = "No detailed info found in related topics."
            else:
                answer = "No detailed info found in related topics."
        return answer or "No specific answer found online." # यदि कोई उत्तर नहीं मिला, तो सामान्य संदेश

    except requests.exceptions.RequestException as e:
        print(f"Error fetching from DuckDuckGo API: {e}")
        return "Sorry, I couldn't connect to the internet to find an answer."
    except ValueError as e: # JSON डिकोडिंग एरर
        print(f"Error decoding JSON from DuckDuckGo API: {e}")
        return "Sorry, there was an issue processing the internet response."


@app.route("/api/chat-with-internet", methods=["POST"]) # <-- यह आपका API एंडपॉइंट है
def chat_with_internet():
    data = request.json
    question = data.get("prompt", "") # <-- frontend से 'prompt' नाम की key आती है

    if not question:
        return jsonify({"success": False, "message": "No question provided"}), 400

    answer = get_internet_answer(question)
    # Frontend को 'success' और 'aiResponse' keys की उम्मीद है
    return jsonify({"success": True, "aiResponse": answer})

if __name__ == "__main__":
    import os
    # Render PORT एनवायरनमेंट वेरिएबल देता है, लोकल के लिए 5000
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False) # प्रोडक्शन में debug=False रखें
