import prisma from "../src/lib/prisma";

async function main() {
  const alice = await prisma.user.upsert({
    where: { email: "alice@prisma.io" },
    update: { name: "Alice" },
    create: {
      email: "alice@prisma.io",
      name: "Alice",
      posts: {
        create: [
          { title: "Getting started with Prisma", published: true },
          { title: "Draft: adapter notes", published: false },
        ],
      },
    },
  });

  const bob = await prisma.user.upsert({
    where: { email: "bob@prisma.io" },
    update: { name: "Bob" },
    create: {
      email: "bob@prisma.io",
      name: "Bob",
      posts: {
        create: [{ title: "Hello from Bob", published: true }],
      },
    },
  });

  const postCount = await prisma.post.count();

  console.log(`Seeded users: ${alice.email}, ${bob.email}`);
  console.log(`Total posts: ${postCount}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
