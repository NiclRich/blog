 # Load libraries
import os
import sys
from PIL import Image
import fire

# define constants
DEFAULT_OUTPUT_PATH = "./"
DOT = "."
SUPPORTED_FORMATS = ("jpeg", ".jpeg", "jpg", ".jpg", ".png", "png")

# define the function to create the output gif.
def combine_to_gif(name:str="output.gif", output_path:str=DEFAULT_OUTPUT_PATH, file_type:str=".png", duration:int=500, print_done:bool=False, *args):
    if output_path == DEFAULT_OUTPUT_PATH:
        output_path = os.getcwd()
    
    try:
        if file_type not in SUPPORTED_FORMATS:
            raise ValueError
        if len(args) == 0:
            args = sys.stdin.read().splitlines() # read from command line
        if len(args) == 0:
            raise ValueError("No images given")
        frames = [Image.open(arg) for arg in args]
        img = frames[0]
        file_path = output_path + "/" + name
        img.save(fp=file_path, format="GIF", append_images=frames,
                 save_all=True, duration=duration, loop=0)
        
        if print_done:
            print("Gif file created", file_path)
    except Exception as e:
        print(e)

if __name__ == "__main__":
    fire.Fire(combine_to_gif)