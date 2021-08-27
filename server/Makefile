all:
	$(CC) $(CFLAGS) $(GFX) -o $(SERVER)

clean:
	rm $(SERVER)

memcheck:
	valgrind --leak-check=full ./$(SERVER)
