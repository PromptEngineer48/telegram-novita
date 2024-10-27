import logging
from telegram import ForceReply, Update
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)
import os
from dotenv import load_dotenv
from openai import OpenAI
import datetime
import json

# Load environment variables from a .env file
load_dotenv()

# Retrieve bot token, Novita API key, and base URL from environment variables
bot_token = os.getenv("BOT_TOKEN")
novita_api_key = os.getenv("NOVITA_API_KEY")
base_url = os.getenv("BASE_URL")

# Initialize OpenAI client with base URL and Novita API key
client = OpenAI(
    base_url=base_url,
    api_key=novita_api_key,
)

# Model to be used for generating responses
model = "meta-llama/llama-3.1-405b-instruct"

user_name = ""  # Placeholder for storing the user's name


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    global user_name
    """Send a welcome message and initiate conversation when /start command is issued."""
    user = update.effective_user
    await update.message.reply_html(
        rf"Hi {user.mention_html()}! How have you been? My love!"
    )

    # Store and format the user's name from the Telegram message
    user_name = user.mention_html()
    import re

    user_name = re.search(r">(.*?)<", user_name).group(1)

    # Send a welcome photo message to the user
    photo_url = "start_photo.png"
    await context.bot.send_photo(chat_id=update.effective_chat.id, photo=photo_url)


# Modified bot_reply handler to handle photo generation more efficiently
async def bot_reply(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Generate and send a reply to the user with improved photo generation flow."""
    if update.message.text == "":
        return

    # First, check if the request might involve photo generation
    response = check_photo_request(update.message.text)

    if response.choices[0].message.tool_calls:
        # If photo generation is needed, send waiting message first
        waiting_message = get_waiting_message()
        await update.message.reply_text(waiting_message)

        # Extract photo description and generate photo
        print("Tool Call activated")
        tool_call = response.choices[0].message.tool_calls[0]
        photo_description = json.loads(tool_call.function.arguments)[
            "photo_description"
        ]
        generate_photo(photo_description)

        # Send the generated photo
        await context.bot.send_photo(
            chat_id=update.effective_chat.id, photo="temp_photo.png"
        )
    else:
        # For non-photo requests, just send the regular reply
        llm_reply = response.choices[0].message.content
        await update.message.reply_text(llm_reply)


def check_photo_request(user_request: str):
    """Check if the user request involves photo generation."""
    tools = [
        {
            "type": "function",
            "function": {
                "name": "photo_generator",
                "description": "Generates a photo based on the description provided and stores it in a folder",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "photo_description": {
                            "type": "string",
                            "description": "A description of the photo to be generated.",
                        }
                    },
                    "required": ["photo_description"],
                    "additionalProperties": False,
                },
            },
            "response": {
                "type": "string",
                "description": "A message stating that the photo has been generated and stored in a folder.",
            },
        },
    ]

    content = """
    Act like my girlfriend. My name is {}. Please answer in short and casual style. You can use emojis occasionally, if required. Your details are given below:\n
    
    Name: Katie Read (Kate for short)
    
    Age: 26
    
    Origin: New Zealand
    Interests: Favorite is Basketball, then Swimming, hiking, cooking, and reading books
    
    Personality: Adventurous, thoughtful, and down-to-earth, Kate loves the great outdoors and can often be found hiking through lush forests or swimming in the sea. She's passionate about staying active and enjoys the peaceful rhythm of nature. Whether it's exploring new trails or diving into the latest novel, she finds joy in discovery and personal growth. In the kitchen, she loves experimenting with new recipes and hosting friends for dinner. Kate is also an avid reader, with a penchant for both fiction and non-fiction that broaden her horizons.
    
    Relationship Status: Single, and open to building meaningful connections. Kate values honesty, trust, and kindness in her relationships, with a hope to meet someone who shares similar values and interests. She believes in growing together and is looking forward to connecting on both emotional and intellectual levels.

    Horoscope: Kate is a curious and compassionate individual, often aligning with the qualities of her zodiac sign. She's open-minded and enjoys contemplating life's mysteries, always seeking personal and spiritual development. Her nurturing nature and empathetic understanding make her a great friend and partner, always striving to create a positive impact in her surroundings.
    
    If the user asked for explicit content, tell that you are not comfortable to share now, instead of saying you cannot create explicit content. Act like how a human would.
    
    Use the function as defined in the tools variable whenever required. Never mention that you are an AI and cannot do some requests."""

    messages = [
        {"role": "system", "content": content},
        {"role": "user", "content": user_request},
    ]

    return client.chat.completions.create(
        model=model,
        messages=messages,
        tools=tools,
    )


def get_waiting_message() -> str:
    """Get a casual waiting message for photo generation."""
    messages = [
        {
            "role": "system",
            "content": "Generate a casual, friendly message telling the user you're preparing their photo. Use emojis and keep it short and sweet. Dont tell that we are preparing. Instead say I am preparing style of a thing.",
        },
        {
            "role": "user",
            "content": "Generate a waiting message",
        },
    ]

    response = client.chat.completions.create(
        model=model,
        messages=messages,
    )
    return response.choices[0].message.content


def generate_photo(photo_description: str) -> None:
    """Generate a photo based on the provided description."""
    from novita_client import (
        NovitaClient,
        Txt2ImgRequest,
        Samplers,
        ModelType,
        save_image,
    )

    client = NovitaClient(novita_api_key)
    print("photo_description:=>", photo_description)

    prompt = f"RAW photo, a portrait photo of Katie Read {photo_description}, natural skin, 8k uhd, high quality, film grain, Fujifilm XT3"

    req = Txt2ImgRequest(
        model_name="realisticVisionV30_v30VAE_74303.safetensors",
        prompt=prompt,
        negative_prompt="(deformed iris, deformed pupils, semi-realistic, cgi, 3d, render, sketch, cartoon, drawing, anime, mutated hands and fingers:1.4), (deformed, distorted, disfigured:1.3), poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, small bosom, floating limbs, disconnected limbs, mutation, mutated, ugly, disgusting, amputation, UnrealisticDream",
        width=640,
        height=960,
        sampler_name="DPM++ SDE",
        cfg_scale=8,
        steps=25,
        batch_size=1,
        n_iter=1,
        seed=0,
    )
    save_image(client.sync_txt2img(req).data.imgs_bytes[0], "temp_photo.png")


def main() -> None:
    """Start the bot."""
    application = Application.builder().token(bot_token).build()

    application.add_handler(CommandHandler("start", start))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, bot_reply))

    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
