package hello;

import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Random;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;

@SpringBootApplication
public class Application {

	static ArrayList<String> theHeapBomb = new ArrayList<>();

	public static String getRandomString() {
		final byte[] array = new byte[512]; // length is bounded by 7
		new Random().nextBytes(array);
		return new String(array, Charset.forName("UTF-8"));
	}

	public static void main(final String[] args) {
		final ApplicationContext ctx = SpringApplication.run(Application.class, args);

		long iterations = 0;
		long lastTime = System.currentTimeMillis();

		while (true) {
			final String randomString = Application.getRandomString();
			Application.theHeapBomb.add(randomString);
			iterations += 1;
			if (iterations % 2000 == 0) {
				final long duration = System.currentTimeMillis() - lastTime;
				lastTime = System.currentTimeMillis();
				final long dataCreated = (iterations * 512 * 2)/1024/1024;
				System.out.println(String.format("iteration %d, %d msecs taken, %d mbytes", iterations, duration, dataCreated));
			}
		}

	}

}
