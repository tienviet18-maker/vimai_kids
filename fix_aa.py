import asyncio
import edge_tts

# Ép dấu chấm than và tăng pitch để giữ nguyên thanh sắc vút lên
TEXT = "ớ!"
VOICE = "vi-VN-HoaiMyNeural"
OUTPUT_PATH = "assets/audio/v_aa.mp3"

async def fix():
    tts = edge_tts.Communicate(text=TEXT, voice=VOICE, rate="-20%", pitch="+5Hz")
    await tts.save(OUTPUT_PATH)
    print("-> Đã tạo đè thành công file v_aa.mp3 với âm: ", TEXT)

if __name__ == "__main__":
    asyncio.run(fix())