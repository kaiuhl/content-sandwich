# Content Sandwich

A state machine that manages the transition between blocks of content.
It automatically binds to the data attributes `data-state-group`, `data-state`, 
and `data-state-transition` to set up states without any boilerplate.

Content Sandwich handles multiple states on a page and works with
nested states by simply nesting the content in the DOM.

## Usage

If you want access to the state group instance, find or initialize it
with `mystates = ContentSandwich('mystategroup')` From here, you can add
transition callbacks or force state transitions from other parts of your
application.

## Example

    <div data-state-group="sandwiches" data-state="bread">
      <h1>Bread</h1>
      <p>First, use Dave's Killer Bread.</p>
      <button data-state-transition="condiments">Next</button>
    </div>

    <div data-state-group="sandwiches" data-state="condiments">
      <h1>Condiments</h1>
      <p>Next, cover the bread with a thin layer of Kewpie Mayo and add
      romaine lettuce and in-season tomato slices.</p>
      <button data-state-transition="meat">Next</button>
    </div>

    <div data-state-group="sandwiches" data-state="meat">
      <h1>Meat</h1>
      <p>Now, add thin sliced italian meat from your favorite butcher.</p>
      <button data-state-transition="cheese">Next</button>
    </div>

    <div data-state-group="sandwiches" data-state="cheese">
      <h1>Cheese</h1>
      <p>Finally, add provolone and put the sandwich in your face!</p>
    </div>
