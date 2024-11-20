import sys
from PIL import Image
import imagehash

def hash_image(image_path):
    image = Image.open(image_path)
    return imagehash.dhash(image)

def compare_images(image1_path, image2_path):
    hash1 = hash_image(image1_path)
    hash2 = hash_image(image2_path)
    return hash1 - hash2

if __name__ == "__main__":
    image1_path = sys.argv[1]
    image2_path = sys.argv[2]
    difference = compare_images(image1_path, image2_path)
    print(difference)