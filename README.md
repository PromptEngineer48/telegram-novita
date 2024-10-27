# AI Girlfriend Telegram Bot 🤖💕

A Telegram chatbot that simulates conversations with an AI girlfriend named Katie Read, powered by LLaMA 3 hosted in Novita GPUs and Novita image generation. The bot features natural conversations, photo generation capabilities, and a distinct personality.

## Features 🌟

- **Natural Conversations**: Engaging chat interactions with a defined personality
- **Image Generation**: Can generate photos based on text descriptions
- **Personality Profile**: Complete background and character traits
- **Casual Communication**: Uses emojis and natural language
- **Error Handling**: Graceful fallbacks for failed operations

## Tech Stack 🛠️

- Python 3.8+
- python-telegram-bot
- LLaMA 3 (via OpenAI-compatible API)
- Novita Client for image generation
- python-dotenv for environment management

## Installation 🔧

1. Clone the repository:
```bash
git clone https://github.com/promptengineer48/telegram-novita.git
cd telegram-novita
```

2. Create a virtual environment:
```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
Create a `.env` file in the root directory with the following:
```plaintext
BOT_TOKEN=your_telegram_bot_token
NOVITA_API_KEY=your_novita_api_key
BASE_URL=your_llama_api_base_url
```

## Configuration ⚙️

### Bot Personality
The bot is configured with the following personality traits:
- Name: Katie Read (Kate)
- Age: 26
- Origin: New Zealand
- Interests: Basketball, Swimming, Hiking, Cooking, Reading
- Personality: Adventurous, thoughtful, down-to-earth

### Image Generation
The image generation uses the following parameters:
- Model: realisticVisionV30_v30VAE
- Resolution: 640x960
- Sampling: DPM++ SDE
- Quality settings optimized for photorealistic output

## Usage 💬

1. Start the bot:
```bash
python virtualgf.py
```

2. In Telegram, search for your bot username and start a chat

3. Available commands:
- `/start` - Begin conversation and receive welcome message
- Any text message will receive a contextual response
- Photo requests are automatically detected and processed

## Code Structure 📁

```plaintext
├── virtualgf.py           # Main bot implementation
├── requirements.txt       # Project dependencies
├── .env                  # Environment variables
└── README.md            # Project documentation
```

### Key Components:

1. **Bot Initialization**
   - Environment variable loading
   - API client setup
   - Command handlers registration

2. **Message Processing**
   - Natural language processing
   - Context management
   - Response generation

3. **Image Generation**
   - Photo request detection
   - Novita API integration
   - Error handling

## Development 👨‍💻

### Adding New Features

1. Create a new branch for your feature:
```bash
git checkout -b feature/your-feature-name
```

2. Make your changes and test thoroughly

3. Submit a pull request with a clear description of changes

### Code Style

- Follow PEP 8 guidelines
- Use meaningful variable names
- Add comments for complex logic
- Include type hints where possible

## Error Handling 🔍

The bot includes comprehensive error handling for:
- API failures
- Image generation issues
- Message processing errors
- Network connectivity problems

## Contributing 🤝

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Submit a pull request

## License 📝

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- LLaMA 3 for the language model
- Novita for image generation capabilities
- Telegram Bot API for the messaging platform

## Support 📧

For support, please open an issue in the GitHub repository or contact [promptengineer48@example.com]

## Disclaimer ⚠️

This bot is created for educational purposes. Please ensure responsible use and respect for privacy and ethical considerations when deploying AI chatbots.

---
Made with ❤️ by [Prompt Engineer 48]
