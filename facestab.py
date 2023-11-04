from argparse import ArgumentParser
from os import environ
from pathlib import Path

from dlib import get_frontal_face_detector, shape_predictor, load_rgb_image
import matplotlib.pyplot as plt
from tqdm import tqdm


def directory(s: str) -> Path:
    """Raises ValueError if path is not a directory"""
    path = Path(s)

    if not path.is_dir():
        raise ValueError(f"{path} is not a directory")

    return path


def main():
    parser = ArgumentParser()

    parser.add_argument(
        "-p",
        "--predictor",
        type=Path,
        help="Uncompressed trained shape predictor",
    )
    parser.add_argument(
        "IMAGES_DIR",
        type=directory,
        help="Directory containing the images to stabilize",
    )

    args = parser.parse_args()
    ppath: Path = (
        args.predictor
        if args.predictor is not None
        else Path(environ["SHAPE_PREDICTOR"])
    )

    detector = get_frontal_face_detector()  # thread unsafe
    predictor = shape_predictor(str(ppath.as_posix()))

    for path in tqdm(list(args.IMAGES_DIR.iterdir())[:1]):
        image = load_rgb_image(path.as_posix())
        plt.imshow(image)
        dets = detector(image, 1)

        for face in dets:
            dots = predictor(image, face).parts()
            xs = [dot.x for dot in dots]
            ys = [dot.y for dot in dots]
            plt.scatter(xs, ys)

    plt.show()


if __name__ == "__main__":
    main()
