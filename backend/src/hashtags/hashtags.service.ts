import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateHashtagDto } from './dto/create-hashtag.dto';

@Injectable()
export class HashtagsService {
  constructor(private prisma: PrismaService) {}

  async create(createHashtagDto: CreateHashtagDto) {
    const hashtag = await this.prisma.hashtag.create({
      data: createHashtagDto,
    });
    return hashtag;
  }
  async findAll() {
    return this.prisma.hashtag.findMany();
  }
}
