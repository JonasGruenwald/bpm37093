import { Ok, Error } from "./gleam.mjs";

import {
  Event$Tick,
  Event$MouseMoved,
  Event$MousePressed,
  Event$MouseReleased,
  MouseButton$MouseButtonLeft,
  MouseButton$MouseButtonMiddle,
  MouseButton$MouseButtonRight
} from './canvas.mjs';


export const register_component = (name, init, update, render, attribute_handlers) => {

  const attributeMap = {};
  for (const [attr, handler] of attribute_handlers) {
    attributeMap[attr] = handler;
  }

  const attributes = Object.keys(attributeMap);

  const component = class Component extends HTMLElement {
    static get observedAttributes() {
      return attributes;
    }

    // Internal
    #container;
    #bounds;
    #resizeObserver;
    #canvas;
    #ctx;
    #model;

    // User-defined
    #init;
    #update;
    #render;

    constructor() {
      super();
      this.#init = init;
      this.#update = update;
      this.#render = render;
      this.#canvas = document.createElement("canvas");
      this.#canvas.style.width = "100%";
      this.#canvas.style.height = "100%";
      this.#ctx = this.#canvas.getContext("2d");
      this.attachShadow({ mode: "open" });
      this.shadowRoot.appendChild(this.#canvas);
    }

    connectedCallback() {
      this.#model = this.#init();
      this.#resizeCanvas();
      window.requestAnimationFrame(this.#loop);

      this.#canvas.addEventListener("mousedown",
        this.#handleMouseDown
      );

      this.#canvas.addEventListener("mouseup",
        this.#handleMouseUp
      );

      this.#canvas.addEventListener("mousemove",
        this.#handleMouseMove
      );

      this.#resizeObserver = new ResizeObserver(() => {
        this.#resizeCanvas();
        this.#render(this.#model, this.#ctx, this.#bounds.width, this.#bounds.height);
      });
      this.#resizeObserver.observe(this.#canvas);

    }

    disconnectedCallback() {
      this.#resizeObserver.unobserve(this.#container);
      this.#canvas.removeEventListener("mousedown",
        this.#handleMouseDown
      );
      this.#canvas.removeEventListener("mouseup",
        this.#handleMouseUp
      );
      this.#canvas.removeEventListener("mousemove",
        this.#handleMouseMove
      );
    }

    attributeChangedCallback(name, oldValue, newValue) {
      const handler = attributeMap[name];
      if (handler) {
        this.#model = handler(newValue, this.#model);
      } else {
        throw new Error(`No handler for attribute: ${name}`);
      }
    }

    #handleMouseDown = (e) => {
      const x = e.offsetX;
      const y = e.offsetY;
      switch (e.button) {
        case 0:
          this.#model = this.#update(this.#model, Event$MousePressed(MouseButton$MouseButtonLeft(), x, y));
          break;
        case 1:
          this.#model = this.#update(this.#model, Event$MousePressed(MouseButton$MouseButtonMiddle(), x, y));
          break;
        case 2:
          this.#model = this.#update(this.#model, Event$MousePressed(MouseButton$MouseButtonRight(), x, y));
          break;
      }
    }

    #handleMouseUp = (e) => {
      switch (e.button) {
        case 0:
          this.#model = this.#update(this.#model, Event$MouseReleased(MouseButton$MouseButtonLeft()));
          break;
        case 1:
          this.#model = this.#update(this.#model, Event$MouseReleased(MouseButton$MouseButtonMiddle()));
          break;
        case 2:
          this.#model = this.#update(this.#model, Event$MouseReleased(MouseButton$MouseButtonRight()));
          break;
      }
    }

    #handleMouseMove = (e) => {
      const x = e.offsetX;
      const y = e.offsetY;
      this.#model = this.#update(this.#model, Event$MouseMoved(x, y));
    }

    #resizeCanvas() {
      this.#bounds = this.#canvas.getBoundingClientRect();
      const { width, height } = this.#bounds;
      this.#canvas.width = width * window.devicePixelRatio;
      this.#canvas.height = height * window.devicePixelRatio;
      this.#ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
    }

    #loop = (timestamp) => {
      this.#model = this.#update(this.#model, Event$Tick(timestamp));
      // TODO maybe only render if the model has changed?
      this.#render(this.#model, this.#ctx, this.#bounds.width, this.#bounds.height);
      window.requestAnimationFrame(this.#loop);
    }
  }

  customElements.define(name, component);
  return new Ok(undefined)
}

export const set_fill_style = (ctx, style) => {
  ctx.fillStyle = style;
};

export const set_stroke_style = (ctx, style) => {
  ctx.strokeStyle = style;
};

export const set_line_width = (ctx, width) => {
  ctx.lineWidth = width;
};

export const set_line_cap = (ctx, cap) => {
  ctx.lineCap = cap;
};

export const set_line_join = (ctx, join) => {
  ctx.lineJoin = join;
};

export const set_font = (ctx, font) => {
  ctx.font = font;
}

export const set_text_align = (ctx, align) => {
  ctx.textAlign = align;
};

export const set_global_alpha = (ctx, alpha) => {
  ctx.globalAlpha = alpha;
};

export const set_global_composite_operation = (ctx, operation) => {
  ctx.globalCompositeOperation = operation;
}

// Drawing operations
export const begin_path = (ctx) => {
  ctx.beginPath();
};

export const move_to = (ctx, x, y) => {
  ctx.moveTo(x, y);
};

export const line_to = (ctx, x, y) => {
  ctx.lineTo(x, y);
};

export const stroke = (ctx) => {
  ctx.stroke();
};

export const ellipse = (ctx, x, y, radiusX, radiusY, rotation, startAngle, endAngle) => {
  ctx.ellipse(x, y, radiusX, radiusY, rotation, startAngle, endAngle);
};

export const fill = (ctx) => {
  ctx.fill();
};

export const fill_text = (ctx, text, x, y) => {
  ctx.fillText(text, x, y);
};

export const fill_rect = (ctx, x, y, width, height) => {
  ctx.fillRect(x, y, width, height);
};

export const arc = (ctx, x, y, radius, startAngle, endAngle) => {
  ctx.arc(x, y, radius, startAngle, endAngle);
};

export const clear_rect = (ctx, x, y, width, height) => {
  ctx.clearRect(x, y, width, height);
};
