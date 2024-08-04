import { component$ } from "@builder.io/qwik";
import type { DocumentHead } from "@builder.io/qwik-city";

export default component$(() => {
  return (
    <>
      <h1>Posts</h1>
      <div>
        Your posts
      </div>
    </>
  );
});

export const head: DocumentHead = {
  title: "Posts",
  meta: [
    {
      name: "description",
      content: "Posts description",
    },
  ],
};
