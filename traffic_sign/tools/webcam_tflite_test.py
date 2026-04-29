from __future__ import annotations

import argparse
from pathlib import Path
from time import perf_counter

import cv2
import numpy as np
from ultralytics import YOLO


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MODEL = ROOT / "assets" / "models" / "best59_float16.tflite"
DEFAULT_LABELS = ROOT / "assets" / "models" / "labels_59.txt"


def load_labels(labels_path: Path) -> list[str]:
    return [line.strip() for line in labels_path.read_text(encoding="utf-8").splitlines() if line.strip()]


def format_label(raw_label: str) -> str:
    return raw_label.replace("_", " ")


def draw_overlay(frame: np.ndarray, text: str, fps: float, score: float | None) -> None:
    label = text if score is None else f"{text} | {score * 100:.1f}%"
    cv2.rectangle(frame, (0, 0), (frame.shape[1], 42), (0, 0, 0), -1)
    cv2.putText(
        frame,
        f"{label} | {fps:.1f} FPS",
        (12, 28),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.8,
        (255, 255, 255),
        2,
        cv2.LINE_AA,
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Live webcam tester for the traffic-sign TFLite model")
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL, help="Path to the .tflite model")
    parser.add_argument("--labels", type=Path, default=DEFAULT_LABELS, help="Path to labels.txt")
    parser.add_argument("--source", type=int, default=0, help="Webcam index (default: 0)")
    parser.add_argument("--imgsz", type=int, default=640, help="Inference size")
    parser.add_argument("--conf", type=float, default=0.12, help="Confidence threshold")
    parser.add_argument("--show", action="store_true", help="Show a preview window")
    parser.add_argument("--max-frames", type=int, default=0, help="Stop after N frames (0 = no limit)")
    args = parser.parse_args()

    if not args.model.exists():
        raise FileNotFoundError(f"Model not found: {args.model}")
    if not args.labels.exists():
        raise FileNotFoundError(f"Labels not found: {args.labels}")

    labels = load_labels(args.labels)
    model = YOLO(str(args.model))

    capture = cv2.VideoCapture(args.source)
    if not capture.isOpened():
        raise RuntimeError(
            f"Could not open webcam index {args.source}. Try another index like --source 1 or 2."
        )

    frame_count = 0
    last_time = perf_counter()
    print(f"Loaded model: {args.model}")
    print(f"Loaded labels: {len(labels)} classes")
    print("Press ESC or q to exit.")

    try:
        while True:
            ok, frame = capture.read()
            if not ok:
                print("Failed to read frame from webcam.")
                break

            start = perf_counter()
            results = model.predict(frame, imgsz=args.imgsz, conf=args.conf, verbose=False)
            elapsed = perf_counter() - start
            fps = 1.0 / max(perf_counter() - last_time, 1e-6)
            last_time = perf_counter()

            result = results[0]
            text = "No detection"
            score = None
            if result.boxes is not None and len(result.boxes) > 0:
                best = max(result.boxes, key=lambda box: float(box.conf[0]))
                class_index = int(best.cls[0])
                score = float(best.conf[0])
                if 0 <= class_index < len(labels):
                    text = format_label(labels[class_index])
                else:
                    text = f"class_{class_index}"

            print(f"frame={frame_count:05d} top={text} score={0.0 if score is None else score:.3f} infer_ms={elapsed*1000:.1f}")

            if args.show:
                draw_overlay(frame, text, fps, score)
                cv2.imshow("Traffic Sign Webcam Test", frame)
                key = cv2.waitKey(1) & 0xFF
                if key in (27, ord('q')):
                    break

            frame_count += 1
            if args.max_frames and frame_count >= args.max_frames:
                break
    finally:
        capture.release()
        cv2.destroyAllWindows()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
